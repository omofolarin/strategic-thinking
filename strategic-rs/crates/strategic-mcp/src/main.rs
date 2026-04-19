use std::net::SocketAddr;

mod server;
mod tools;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr: SocketAddr = "0.0.0.0:8080".parse()?;
    println!("strategic-mcp listening on {addr}");

    // Phase 4 skeleton — tasks.md 4.3.
    // let app = server::router();
    // let listener = tokio::net::TcpListener::bind(addr).await?;
    // axum::serve(listener, app).await?;

    Ok(())
}
