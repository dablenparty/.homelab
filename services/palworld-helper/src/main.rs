use std::{
    collections::HashMap,
    path::PathBuf,
    sync::{Arc, LazyLock},
};

use anyhow::{Context, bail};
use axum::{
    Router,
    extract::State,
    response::{IntoResponse, Response},
    routing::{get, post},
};
use maud::{Markup, html};
use tokio::{
    process::{Child, Command},
    sync::Mutex,
};

const SERVER_PATH: &str = "/home/hunterd/.steam/steam/SteamApps/common/PalServer";
const SERVER_URL: &str = "127.0.0.1";
const SERVER_PORT: usize = 8212;
const ADMIN_PASSWORD: &str = "borden3asset!CHARCOAL7consult";

static REQWEST_CLIENT: LazyLock<reqwest::Client> = LazyLock::new(reqwest::Client::new);

#[derive(Debug, Default)]
struct SharedState {
    /// If this is Some, the server is running
    server_pid: Option<Child>,
}

async fn _check() -> anyhow::Result<Markup> {
    let response = REQWEST_CLIENT
        .get(format!("http://{SERVER_URL}:{SERVER_PORT}/v1/api/info"))
        .header("Accept", "application/json")
        .basic_auth("admin", Some(ADMIN_PASSWORD))
        .send()
        .await
        .context("failed to send check request")?
        .error_for_status()?;
    let output = response
        .text()
        .await
        .context("failed to get text from response")?;

    let markup = html! {
        p {
            Received the following output from the Palworld server:
            pre {
                (output)
            }
        }
    };

    Ok(markup)
}

async fn check() -> Response {
    let response = _check().await;
    match response {
        Ok(res) => res.into_response(),
        Err(err) => html! {
            pre {
                (err)}
        }
        .into_response(),
    }
}

async fn _start(state: Arc<Mutex<SharedState>>) -> anyhow::Result<Markup> {
    {
        let mut s = state.lock().await;
        if let Some(ref mut proc) = s.server_pid
            && proc
                .try_wait()
                .context("failed to check server process")?
                .is_none()
        {
            let msg = "The server is already running!";
            let markup = html! {
                p {
                    (msg)
                 }
            };
            return Ok(markup);
        }
    }
    let start_script = PathBuf::from(SERVER_PATH).join("start.sh");
    let proc = Command::new(start_script)
        .current_dir(SERVER_PATH)
        .spawn()
        .context("failed to start server process")?;
    {
        let mut s = state.lock().await;
        s.server_pid = Some(proc);
    }
    let msg = "Server started successfully Please allow a few minutes for it to start up";
    let markup = html! {
        p {
            (msg)
        }
    };

    Ok(markup)
}

async fn start(State(state): State<Arc<Mutex<SharedState>>>) -> Response {
    let response = _start(state).await;
    match response {
        Ok(res) => res.into_response(),
        Err(err) => html! {
            pre{
                (err)
             }
        }
        .into_response(),
    }
}

async fn _stop(state: Arc<Mutex<SharedState>>) -> anyhow::Result<Markup> {
    {
        let mut s = state.lock().await;
        if let Some(ref mut proc) = s.server_pid
            && proc
                .try_wait()
                .context("failed to check server process")?
                .is_some()
        {
            let msg = "The server is already stopped!";
            let markup = html! {
                p {
                    (msg)
                 }
            };
            return Ok(markup);
        }
    }

    let _save_response = REQWEST_CLIENT
        .post(format!("http://{SERVER_URL}:{SERVER_PORT}/v1/api/save"))
        .header("Content-Length", 0)
        .basic_auth("admin", Some(ADMIN_PASSWORD))
        .send()
        .await
        .context("failed to send save request")?
        .error_for_status()?;

    let mut shutdown_body = HashMap::new();
    shutdown_body.insert("waittime", "1");
    shutdown_body.insert("message", "Server will shutdown now");
    let shutdown_response = REQWEST_CLIENT
        .post(format!("http://{SERVER_URL}:{SERVER_PORT}/v1/api/shutdown"))
        .header("Accept", "application/json")
        .json(&shutdown_body)
        .basic_auth("admin", Some(ADMIN_PASSWORD))
        .send()
        .await
        .context("failed to send shutdown request")?
        .error_for_status()?;
    let output = shutdown_response
        .text()
        .await
        .context("failed to get text from response")?;

    {
        let mut s = state.lock().await;
        let mut server_handle = s
            .server_pid
            .take()
            .expect("tried to take from empty Option");
        let exit_status = server_handle
            .wait()
            .await
            .context("failed to wait for server to close")?;
        println!("server exited with status: {exit_status:#?}");
    }

    let markup = html! {
        p {
            Received the following output from the Palworld server:
            pre {
                (output)
            }
        }
    };

    Ok(markup)
}

async fn stop(State(state): State<Arc<Mutex<SharedState>>>) -> Response {
    let response = _stop(state).await;
    match response {
        Ok(res) => res.into_response(),
        Err(err) => html! {
            pre {
                (err)
            }
        }
        .into_response(),
    }
}

async fn _update(state: Arc<Mutex<SharedState>>) -> anyhow::Result<Markup> {
    {
        let mut s = state.lock().await;
        if let Some(ref mut proc) = s.server_pid
            && proc
                .try_wait()
                .context("failed to check server process")?
                .is_none()
        {
            bail!("The server is already running, please stop it first!");
        }
    }

    todo!("update button")
}

async fn root() -> Markup {
    html! {
        form method="post" action="/check" {
            button type="submit" {
                "Check Server"
            }
        }

        form method="post" action="/start" {
            button type="submit" {
                "Start Server"
            }
        }

        form method="post" action="/stop" {
            button type="submit" {
                "Stop Server"
            }
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    println!("Hello, world!");

    let app = Router::new()
        .route("/", get(root))
        .route("/check", post(check))
        .route("/start", post(start))
        .route("/stop", post(stop))
        .with_state(Arc::new(Mutex::new(SharedState::default())));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:42069")
        .await
        .context("failed to start TCP listener")?;
    axum::serve(listener, app)
        .await
        .context("failed to serve app")?;

    Ok(())
}
