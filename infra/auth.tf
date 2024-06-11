# Creates an Identity Platform config.
# Also enables Firebase Authentication with Identity Platform in the project if not.
resource "google_identity_platform_config" "auth" {
  provider = google-beta
  project  = google_project.default.project_id

  autodelete_anonymous_users = false

  # Wait for identitytoolkit.googleapis.com to be enabled before initializing Authentication.
  depends_on = [
    google_project_service.default,
  ]
}

resource "google_identity_platform_project_default_config" "auth" {
  provider = google-beta
  project  = google_project.default.project_id
  sign_in {
    allow_duplicate_emails = false

    anonymous {
      enabled = true
    }
  }

  depends_on = [
    google_identity_platform_config.auth
  ]
}
