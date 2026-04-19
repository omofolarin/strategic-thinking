# @strategic begin ... end
#
# Parses a natural-language-ish block into a StrategicWorld. Grammar:
#
#   player <Name> can [<action>, <action>, ...]
#   <Name> moves first
#   <Name> threatens: if <Opponent> <action> => <Name> <retaliation>
#   <Name> commits to <action>
#   payoff:
#       (<action>, <action>) => (<n>, <n>)
#       ...
#
# Error messages point to the source line in the DSL block.
# Phase 1 skeleton — tasks.md 1.6.

macro strategic(expr)
    error("Phase 1: @strategic macro not yet implemented (tasks.md 1.6)")
end
