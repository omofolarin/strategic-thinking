"""
    validate_jgdl(json) -> Vector{ValidationError}

Two-pass validation:
  1. JSON Schema structural validation (v1.1.0)
  2. Semantic cross-references (payoff keys, trait IDs, uniqueness, etc.)
"""
struct ValidationError
    path::String
    message::String
end

const _SCHEMA_PATH = joinpath(
    @__DIR__, "..", "..", "..", "jgdl", "schema", "v1.1.0.schema.json")
const _JGDL_SCHEMA = Ref{Any}(nothing)

function _schema()
    if _JGDL_SCHEMA[] === nothing
        _JGDL_SCHEMA[] = JSONSchema.Schema(JSON.parsefile(_SCHEMA_PATH))
    end
    _JGDL_SCHEMA[]
end

function validate_jgdl(json_str::AbstractString)::Vector{ValidationError}
    validate_jgdl(JSON.parse(json_str))
end

function validate_jgdl(doc::AbstractDict)::Vector{ValidationError}
    result = JSONSchema.validate(doc, _schema())
    result === nothing || begin
        path = isempty(result.path) ? "/" : join(result.path, "/")
        return [ValidationError(path, result.reason)]
    end
    _validate_semantics(doc)
end

function _validate_semantics(doc::AbstractDict)::Vector{ValidationError}
    errors = ValidationError[]
    world = get(doc, "world", nothing)
    world === nothing && return errors

    actions = get(world, "actions", [])
    players = get(world, "players", [])
    traits = get(world, "traits", [])
    payoffs = get(world, "payoffs", nothing)
    structure = get(world, "structure", nothing)

    action_ids = [string(get(a, "id", "")) for a in actions]
    player_ids = [string(get(p, "id", "")) for p in players]
    known_action_ids = Set(action_ids)
    known_player_ids = Set(player_ids)

    # 1. Unique player IDs
    if length(player_ids) != length(Set(player_ids))
        dupes = [id for id in player_ids if count(==(id), player_ids) > 1] |> unique
        push!(errors, ValidationError("/world/players",
            "Duplicate player ids: $(join(dupes, ", "))"))
    end

    # 2. Unique action IDs within each player
    for p in players
        pid = string(get(p, "id", ""))
        p_acts = [string(get(a, "id", ""))
                  for a in actions
                  if string(get(a, "player_id", "")) == pid]
        if length(p_acts) != length(Set(p_acts))
            dupes = [id for id in p_acts if count(==(id), p_acts) > 1] |> unique
            push!(errors,
                ValidationError("/world/actions",
                    "Player '$pid' has duplicate action ids: $(join(dupes, ", "))"))
        end
    end

    # 3. Action player_id references a declared player
    for a in actions
        pid = string(get(a, "player_id", ""))
        pid ∉ known_player_ids &&
            push!(errors,
                ValidationError("/world/actions/$(get(a,"id",""))",
                    "Action '$(get(a,"id",""))' references undeclared player '$pid'"))
    end

    if payoffs !== nothing && get(payoffs, "type", "") == "terminal_matrix"
        matrix = get(payoffs, "matrix", Dict())

        # 4. Payoff key segments reference declared action IDs
        for key in keys(matrix)
            for seg in split(string(key), ".")
                seg == "*" && continue
                seg ∉ known_action_ids &&
                    push!(errors,
                        ValidationError("/world/payoffs/matrix/$key",
                            "Payoff key segment '$seg' does not match any declared action id. " *
                            "Known: $(join(sort(collect(known_action_ids)), ", "))"))
            end
        end

        # 5. Payoff matrix completeness (warn only — wildcard entries count as covering)
        if !isempty(players) && !isempty(actions)
            player_action_sets = Dict(
                string(get(p,
                    "id",
                    "")) => [string(get(a, "id", ""))
                             for a in actions
                             if string(get(a, "player_id", "")) == string(get(p, "id", ""))]
            for p in players
            )
            ordered_players = player_ids
            if length(ordered_players) == 2
                p1_acts = get(player_action_sets, ordered_players[1], String[])
                p2_acts = get(player_action_sets, ordered_players[2], String[])
                for a1 in p1_acts, a2 in p2_acts

                    key = "$a1.$a2"
                    # Check exact match or wildcard coverage
                    covered = haskey(matrix, key) ||
                              any(
                        k -> endswith(string(k), ".*") &&
                             startswith(key, string(k)[1:(end - 1)]),
                        keys(matrix))
                    covered || push!(errors,
                        ValidationError("/world/payoffs/matrix",
                            "Missing payoff entry for outcome '$key'. " *
                            "Add ($a1, $a2) => (...) or use a wildcard."))
                end
            end
        end
    end

    # 6. Trait references valid player/action IDs
    for t in traits
        params = get(t, "parameters", Dict())
        trait_type = string(get(t, "type", ""))
        tid = string(get(t, "id", ""))

        pid = string(get(params, "player_id", ""))
        if !isempty(pid) && pid ∉ known_player_ids
            push!(errors,
                ValidationError("/world/traits/$tid",
                    "Trait '$tid' references undeclared player '$pid'"))
        end

        for key in
            ("committed_action", "forbidden_action", "retaliation_action", "trigger_action")
            aid = string(get(params, key, ""))
            if !isempty(aid) && aid ∉ known_action_ids
                push!(errors,
                    ValidationError("/world/traits/$tid",
                        "Trait '$tid' parameter '$key' references undeclared action '$aid'"))
            end
        end

        # 7. Mixed strategy probabilities sum to ~1
        if trait_type == "MixedStrategy"
            dist = get(params, "distribution", Dict())
            total = sum(values(dist); init = 0.0)
            abs(total - 1.0) > 0.01 &&
                push!(errors,
                    ValidationError("/world/traits/$tid/parameters/distribution",
                        "MixedStrategy distribution sums to $(round(total; digits=4)), expected 1.0"))
        end

        # 8. Brinkmanship probability in [0, 1]
        if trait_type == "Brinkmanship"
            p = get(params, "catastrophe_probability", nothing)
            p !== nothing && (p < 0 || p > 1) &&
                push!(errors,
                    ValidationError(
                        "/world/traits/$tid/parameters/catastrophe_probability",
                        "Brinkmanship catastrophe_probability=$p must be in [0, 1]"))
        end
    end

    # 9. Sequential order references declared players
    if structure !== nothing && get(structure, "type", "") == "sequential"
        for pid in get(structure, "order", [])
            string(pid) ∉ known_player_ids &&
                push!(errors,
                    ValidationError("/world/structure/order",
                        "Move order references undeclared player '$(pid)'"))
        end
    end

    # 10. Repeated structure has discount_factor
    if structure !== nothing && get(structure, "type", "") == "repeated"
        get(structure, "discount_factor", nothing) === nothing &&
            push!(errors, ValidationError("/world/structure",
                "Repeated structure missing discount_factor"))
    end

    # 11. Provenance parent_id format
    for (i, node) in enumerate(get(world, "provenance", []))
        pid = string(get(node, "parent_id", ""))
        op = string(get(node, "operation", ""))
        if op != "initial_construction" && !isempty(pid) &&
           !startswith(pid, "sha256:") && pid != ""
            push!(errors,
                ValidationError("/world/provenance/$i/parent_id",
                    "parent_id '$pid' should be empty string or 'sha256:...' format"))
        end
    end

    errors
end
