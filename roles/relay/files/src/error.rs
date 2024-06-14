use thiserror::Error;

#[derive(Debug, Error)]
pub enum RelayBotError {
    /// The user is attempting to use a command that they do not have access to
    #[error("you do not have access to that command")]
    UserNoAccess(),
    /// The interaction is missing a required parameter
    #[error("missing parameter: {0}")]
    MissingParameter(String),
    /// The user has supplied an invalid internal server name
    #[error("no server with internal name {0}")]
    ServerNonExist(String),
    /// [sourcon] error
    #[error("sourcon error: {0}")]
    RconConnectFailed(#[from] sourcon::error::RconError)
}