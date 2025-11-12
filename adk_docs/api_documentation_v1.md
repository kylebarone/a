# FastAPI

**Version:** 0.1.0

**OpenAPI Version:** 3.1.0

---

## Table of Contents

1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
   - [Application Management](#application-management)
   - [Debug & Tracing](#debug-tracing)
   - [Evaluation Management](#evaluation-management)
   - [Other Endpoints](#other-endpoints)
   - [Session Management](#session-management)
8. [Data Models](#data-models)

---

## Overview

This API contains 23 endpoints organized into 5 categories and defines 81 data models.

### Endpoint Categories

- **Application Management:** 1 endpoint(s)
- **Debug & Tracing:** 2 endpoint(s)
- **Evaluation Management:** 6 endpoint(s)
- **Other Endpoints:** 7 endpoint(s)
- **Session Management:** 7 endpoint(s)

---

## API Endpoints


## Application Management


### `/list-apps`

#### GET

**Summary:** List Apps

**Operation ID:** `list_apps_list_apps_get`


**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[string]

---

## Debug & Tracing


### `/debug/trace/session/{session_id}`

#### GET

**Summary:** Get Session Trace

**Operation ID:** `get_session_trace_debug_trace_session__session_id__get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `session_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/debug/trace/{event_id}`

#### GET

**Summary:** Get Trace Dict

**Operation ID:** `get_trace_dict_debug_trace__event_id__get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `event_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

## Evaluation Management


### `/apps/{app_name}/eval_sets`

#### GET

**Summary:** List Eval Sets

Lists all eval sets for the given app.

**Operation ID:** `list_eval_sets_apps__app_name__eval_sets_get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[string]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/eval_sets/{eval_set_id}`

#### POST

**Summary:** Create Eval Set

Creates an eval set, given the id.

**Operation ID:** `create_eval_set_apps__app_name__eval_sets__eval_set_id__post`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_set_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/eval_sets/{eval_set_id}/add_session`

#### POST

**Summary:** Add Session To Eval Set

**Operation ID:** `add_session_to_eval_set_apps__app_name__eval_sets__eval_set_id__add_session_post`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_set_id` | path | string | ✓ |  |

**Request Body:**

- **Content-Type:** `application/json`
- **Schema:** `AddSessionToEvalSetRequest`

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/eval_sets/{eval_set_id}/evals`

#### GET

**Summary:** List Evals In Eval Set

Lists all evals in an eval set.

**Operation ID:** `list_evals_in_eval_set_apps__app_name__eval_sets__eval_set_id__evals_get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_set_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[string]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/eval_sets/{eval_set_id}/evals/{eval_case_id}`

#### GET

**Summary:** Get Eval

Gets an eval case in an eval set.

**Operation ID:** `get_eval_apps__app_name__eval_sets__eval_set_id__evals__eval_case_id__get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_set_id` | path | string | ✓ |  |
| `eval_case_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** `EvalCase-Output`
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---
#### PUT

**Summary:** Update Eval

**Operation ID:** `update_eval_apps__app_name__eval_sets__eval_set_id__evals__eval_case_id__put`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_set_id` | path | string | ✓ |  |
| `eval_case_id` | path | string | ✓ |  |

**Request Body:**

- **Content-Type:** `application/json`
- **Schema:** `EvalCase-Input`

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---
#### DELETE

**Summary:** Delete Eval

**Operation ID:** `delete_eval_apps__app_name__eval_sets__eval_set_id__evals__eval_case_id__delete`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_set_id` | path | string | ✓ |  |
| `eval_case_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/eval_sets/{eval_set_id}/run_eval`

#### POST

**Summary:** Run Eval

Runs an eval given the details in the eval request.

**Operation ID:** `run_eval_apps__app_name__eval_sets__eval_set_id__run_eval_post`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_set_id` | path | string | ✓ |  |

**Request Body:**

- **Content-Type:** `application/json`
- **Schema:** `RunEvalRequest`

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[`RunEvalResult`]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

## Other Endpoints


### `/`

#### GET

**Summary:** Redirect Root To Dev Ui

**Operation ID:** `redirect_root_to_dev_ui__get`


**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any

---

### `/apps/{app_name}/eval_results`

#### GET

**Summary:** List Eval Results

Lists all eval results for the given app.

**Operation ID:** `list_eval_results_apps__app_name__eval_results_get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[string]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/eval_results/{eval_result_id}`

#### GET

**Summary:** Get Eval Result

Gets the eval result for the given eval id.

**Operation ID:** `get_eval_result_apps__app_name__eval_results__eval_result_id__get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `eval_result_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** `EvalSetResult`
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/dev-ui`

#### GET

**Summary:** Redirect Dev Ui Add Slash

**Operation ID:** `redirect_dev_ui_add_slash_dev_ui_get`


**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any

---

### `/health`

#### GET

**Summary:** Health

Health check endpoint

**Operation ID:** `health_health_get`


**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any

---

### `/run`

#### POST

**Summary:** Agent Run

**Operation ID:** `agent_run_run_post`


**Request Body:**

- **Content-Type:** `application/json`
- **Schema:** `AgentRunRequest`

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[`Event-Output`]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/run_sse`

#### POST

**Summary:** Agent Run Sse

**Operation ID:** `agent_run_sse_run_sse_post`


**Request Body:**

- **Content-Type:** `application/json`
- **Schema:** `AgentRunRequest`

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

## Session Management


### `/apps/{app_name}/users/{user_id}/sessions`

#### GET

**Summary:** List Sessions

**Operation ID:** `list_sessions_apps__app_name__users__user_id__sessions_get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[`Session`]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---
#### POST

**Summary:** Create Session

**Operation ID:** `create_session_apps__app_name__users__user_id__sessions_post`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |

**Request Body:**

- **Content-Type:** `application/json`
- **Schema:** `Body_create_session_apps__app_name__users__user_id__sessions_post`

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** `Session`
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/users/{user_id}/sessions/{session_id}`

#### GET

**Summary:** Get Session

**Operation ID:** `get_session_apps__app_name__users__user_id__sessions__session_id__get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** `Session`
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---
#### POST

**Summary:** Create Session With Id

**Operation ID:** `create_session_with_id_apps__app_name__users__user_id__sessions__session_id__post`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |

**Request Body:**

- **Content-Type:** `application/json`
- **Schema:** Object (any) | null

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** `Session`
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---
#### DELETE

**Summary:** Delete Session

**Operation ID:** `delete_session_apps__app_name__users__user_id__sessions__session_id__delete`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/users/{user_id}/sessions/{session_id}/artifacts`

#### GET

**Summary:** List Artifact Names

**Operation ID:** `list_artifact_names_apps__app_name__users__user_id__sessions__session_id__artifacts_get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[string]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/users/{user_id}/sessions/{session_id}/artifacts/{artifact_name}`

#### GET

**Summary:** Load Artifact

**Operation ID:** `load_artifact_apps__app_name__users__user_id__sessions__session_id__artifacts__artifact_name__get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |
| `artifact_name` | path | string | ✓ |  |
| `version` | query | integer | null |  |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** `Part-Output` | null
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---
#### DELETE

**Summary:** Delete Artifact

**Operation ID:** `delete_artifact_apps__app_name__users__user_id__sessions__session_id__artifacts__artifact_name__delete`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |
| `artifact_name` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/users/{user_id}/sessions/{session_id}/artifacts/{artifact_name}/versions`

#### GET

**Summary:** List Artifact Versions

**Operation ID:** `list_artifact_versions_apps__app_name__users__user_id__sessions__session_id__artifacts__artifact_name__versions_get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |
| `artifact_name` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Array[integer]
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/users/{user_id}/sessions/{session_id}/artifacts/{artifact_name}/versions/{version_id}`

#### GET

**Summary:** Load Artifact Version

**Operation ID:** `load_artifact_version_apps__app_name__users__user_id__sessions__session_id__artifacts__artifact_name__versions__version_id__get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |
| `artifact_name` | path | string | ✓ |  |
| `version_id` | path | integer | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** `Part-Output` | null
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

### `/apps/{app_name}/users/{user_id}/sessions/{session_id}/events/{event_id}/graph`

#### GET

**Summary:** Get Event Graph

**Operation ID:** `get_event_graph_apps__app_name__users__user_id__sessions__session_id__events__event_id__graph_get`

**Parameters:**

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| `app_name` | path | string | ✓ |  |
| `user_id` | path | string | ✓ |  |
| `session_id` | path | string | ✓ |  |
| `event_id` | path | string | ✓ |  |

**Responses:**

- **200** - Successful Response
  - **Content-Type:** `application/json`
  - **Schema:** Any
- **422** - Validation Error
  - **Content-Type:** `application/json`
  - **Schema:** `HTTPValidationError`

---

---

## Data Models

This section documents all the data models/schemas used in the API.


### APIKey

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `SecuritySchemeType` |  |  |
| `description` | string | null |  | Description |
| `in` | `APIKeyIn` | ✓ |  |
| `name` | string | ✓ | Name |

*Allows additional properties of any type*


### APIKeyIn

**Type:** `string`

**Allowed Values:**

- `query`
- `header`
- `cookie`


### AddSessionToEvalSetRequest

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `evalId` | string | ✓ | Evalid |
| `sessionId` | string | ✓ | Sessionid |
| `userId` | string | ✓ | Userid |


### AgentRunRequest

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `appName` | string | ✓ | Appname |
| `userId` | string | ✓ | Userid |
| `sessionId` | string | ✓ | Sessionid |
| `newMessage` | `Content-Input` | ✓ |  |
| `streaming` | boolean |  | Streaming |


### AuthConfig-Input

The auth config sent by tool asking client to collect auth credentials and

adk and client will help to fill in the response

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `authScheme` | `APIKey` | `HTTPBase` | `OAuth2-Input` | `OpenIdConnect` | `HTTPBearer` | `OpenIdConnectWithConfig` | ✓ | Authscheme |
| `rawAuthCredential` | `AuthCredential-Input` |  |  |
| `exchangedAuthCredential` | `AuthCredential-Input` |  |  |
| `credentialKey` | string | null |  | Credentialkey |

*Allows additional properties of any type*


### AuthConfig-Output

The auth config sent by tool asking client to collect auth credentials and

adk and client will help to fill in the response

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `authScheme` | `APIKey` | `HTTPBase` | `OAuth2-Output` | `OpenIdConnect` | `HTTPBearer` | `OpenIdConnectWithConfig` | ✓ | Authscheme |
| `rawAuthCredential` | `AuthCredential-Output` |  |  |
| `exchangedAuthCredential` | `AuthCredential-Output` |  |  |
| `credentialKey` | string | null |  | Credentialkey |

*Allows additional properties of any type*


### AuthCredential-Input

Data class representing an authentication credential.

To exchange for the actual credential, please use
CredentialExchanger.exchange_credential().

Examples: API Key Auth
AuthCredential(
    auth_type=AuthCredentialTypes.API_KEY,
    api_key="1234",
)

Example: HTTP Auth
AuthCredential(
    auth_type=AuthCredentialTypes.HTTP,
    http=HttpAuth(
        scheme="basic",
        credentials=HttpCredentials(username="user", password="password"),
    ),
)

Example: OAuth2 Bearer Token in HTTP Header
AuthCredential(
    auth_type=AuthCredentialTypes.HTTP,
    http=HttpAuth(
        scheme="bearer",
        credentials=HttpCredentials(token="eyAkaknabna...."),
    ),
)

Example: OAuth2 Auth with Authorization Code Flow
AuthCredential(
    auth_type=AuthCredentialTypes.OAUTH2,
    oauth2=OAuth2Auth(
        client_id="1234",
        client_secret="secret",
    ),
)

Example: OpenID Connect Auth
AuthCredential(
    auth_type=AuthCredentialTypes.OPEN_ID_CONNECT,
    oauth2=OAuth2Auth(
        client_id="1234",
        client_secret="secret",
        redirect_uri="https://example.com",
        scopes=["scope1", "scope2"],
    ),
)

Example: Auth with resource reference
AuthCredential(
    auth_type=AuthCredentialTypes.API_KEY,
    resource_ref="projects/1234/locations/us-central1/resources/resource1",
)

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `authType` | `AuthCredentialTypes` | ✓ |  |
| `resourceRef` | string | null |  | Resourceref |
| `apiKey` | string | null |  | Apikey |
| `http` | `HttpAuth` | null |  |  |
| `serviceAccount` | `ServiceAccount` | null |  |  |
| `oauth2` | `OAuth2Auth` | null |  |  |

*Allows additional properties of any type*


### AuthCredential-Output

Data class representing an authentication credential.

To exchange for the actual credential, please use
CredentialExchanger.exchange_credential().

Examples: API Key Auth
AuthCredential(
    auth_type=AuthCredentialTypes.API_KEY,
    api_key="1234",
)

Example: HTTP Auth
AuthCredential(
    auth_type=AuthCredentialTypes.HTTP,
    http=HttpAuth(
        scheme="basic",
        credentials=HttpCredentials(username="user", password="password"),
    ),
)

Example: OAuth2 Bearer Token in HTTP Header
AuthCredential(
    auth_type=AuthCredentialTypes.HTTP,
    http=HttpAuth(
        scheme="bearer",
        credentials=HttpCredentials(token="eyAkaknabna...."),
    ),
)

Example: OAuth2 Auth with Authorization Code Flow
AuthCredential(
    auth_type=AuthCredentialTypes.OAUTH2,
    oauth2=OAuth2Auth(
        client_id="1234",
        client_secret="secret",
    ),
)

Example: OpenID Connect Auth
AuthCredential(
    auth_type=AuthCredentialTypes.OPEN_ID_CONNECT,
    oauth2=OAuth2Auth(
        client_id="1234",
        client_secret="secret",
        redirect_uri="https://example.com",
        scopes=["scope1", "scope2"],
    ),
)

Example: Auth with resource reference
AuthCredential(
    auth_type=AuthCredentialTypes.API_KEY,
    resource_ref="projects/1234/locations/us-central1/resources/resource1",
)

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `authType` | `AuthCredentialTypes` | ✓ |  |
| `resourceRef` | string | null |  | Resourceref |
| `apiKey` | string | null |  | Apikey |
| `http` | `HttpAuth` | null |  |  |
| `serviceAccount` | `ServiceAccount` | null |  |  |
| `oauth2` | `OAuth2Auth` | null |  |  |

*Allows additional properties of any type*


### AuthCredentialTypes

Represents the type of authentication credential.

**Type:** `string`

**Allowed Values:**

- `apiKey`
- `http`
- `oauth2`
- `openIdConnect`
- `serviceAccount`


### Blob

Content blob.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `displayName` | string | null |  | Optional. Display name of the blob. Used to provide a label or filename to distinguish blobs. This field is not currently used in the Gemini GenerateContent calls. |
| `data` | string | null |  | Required. Raw bytes. |
| `mimeType` | string | null |  | Required. The IANA standard MIME type of the source data. |


### Body_create_session_apps__app_name__users__user_id__sessions_post

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `state` | Object (any) | null |  | State |
| `events` | Array[`Event-Input`] | null |  | Events |


### CodeExecutionResult

Result of executing the [ExecutableCode].

Always follows a `part` containing the [ExecutableCode].

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `outcome` | `Outcome` | null |  | Required. Outcome of the code execution. |
| `output` | string | null |  | Optional. Contains stdout when code execution is successful, stderr or other description otherwise. |


### Content-Input

Contains the multi-part content of a message.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `parts` | Array[`Part-Input`] | null |  | List of parts that constitute a single message. Each part may have
      a different IANA MIME type. |
| `role` | string | null |  | Optional. The producer of the content. Must be either 'user' or
      'model'. Useful to set for multi-turn conversations, otherwise can be
      empty. If role is not specified, SDK will determine the role. |


### Content-Output

Contains the multi-part content of a message.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `parts` | Array[`Part-Output`] | null |  | List of parts that constitute a single message. Each part may have
      a different IANA MIME type. |
| `role` | string | null |  | Optional. The producer of the content. Must be either 'user' or
      'model'. Useful to set for multi-turn conversations, otherwise can be
      empty. If role is not specified, SDK will determine the role. |


### EvalCase-Input

An eval case.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `evalId` | string | ✓ | Evalid |
| `conversation` | Array[`Invocation-Input`] | ✓ | Conversation |
| `sessionInput` | `SessionInput` | null |  |  |
| `creationTimestamp` | number |  | Creationtimestamp |


### EvalCase-Output

An eval case.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `evalId` | string | ✓ | Evalid |
| `conversation` | Array[`Invocation-Output`] | ✓ | Conversation |
| `sessionInput` | `SessionInput` | null |  |  |
| `creationTimestamp` | number |  | Creationtimestamp |


### EvalCaseResult

Case level evaluation results.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `evalSetFile` | string | null |  | This field is deprecated, use eval_set_id instead. |
| `evalSetId` | string |  | Evalsetid |
| `evalId` | string |  | Evalid |
| `finalEvalStatus` | `EvalStatus` | ✓ |  |
| `evalMetricResults` | Array[array] | null |  | This field is deprecated, use overall_eval_metric_results instead. |
| `overallEvalMetricResults` | Array[`EvalMetricResult`] | ✓ | Overallevalmetricresults |
| `evalMetricResultPerInvocation` | Array[`EvalMetricResultPerInvocation`] | ✓ | Evalmetricresultperinvocation |
| `sessionId` | string | ✓ | Sessionid |
| `sessionDetails` | `Session` | null |  |  |
| `userId` | string | null |  | Userid |


### EvalMetric

A metric used to evaluate a particular aspect of an eval case.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `metricName` | string | ✓ | Metricname |
| `threshold` | number | ✓ | Threshold |


### EvalMetricResult

The actual computed score/value of a particular EvalMetric.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `metricName` | string | ✓ | Metricname |
| `threshold` | number | ✓ | Threshold |
| `score` | number | null |  | Score |
| `evalStatus` | `EvalStatus` | ✓ |  |


### EvalMetricResultPerInvocation

Eval metric results per invocation.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `actualInvocation` | `Invocation-Output` | ✓ |  |
| `expectedInvocation` | `Invocation-Output` | ✓ |  |
| `evalMetricResults` | Array[`EvalMetricResult`] |  | Evalmetricresults |


### EvalSetResult

Eval set level evaluation results.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `evalSetResultId` | string | ✓ | Evalsetresultid |
| `evalSetResultName` | string | null |  | Evalsetresultname |
| `evalSetId` | string | ✓ | Evalsetid |
| `evalCaseResults` | Array[`EvalCaseResult`] |  | Evalcaseresults |
| `creationTimestamp` | number |  | Creationtimestamp |


### EvalStatus

**Type:** `integer`

**Allowed Values:**

- `1`
- `2`
- `3`


### Event-Input

Represents an event in a conversation between agents and users.

It is used to store the content of the conversation, as well as the actions
taken by the agents like function calls, etc.

Attributes:
  invocation_id: The invocation ID of the event.
  author: "user" or the name of the agent, indicating who appended the event
    to the session.
  actions: The actions taken by the agent.
  long_running_tool_ids: The ids of the long running function calls.
  branch: The branch of the event.
  id: The unique identifier of the event.
  timestamp: The timestamp of the event.
  is_final_response: Whether the event is the final response of the agent.
  get_function_calls: Returns the function calls in the event.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `content` | `Content-Input` | null |  |  |
| `groundingMetadata` | `GroundingMetadata-Input` | null |  |  |
| `partial` | boolean | null |  | Partial |
| `turnComplete` | boolean | null |  | Turncomplete |
| `errorCode` | string | null |  | Errorcode |
| `errorMessage` | string | null |  | Errormessage |
| `interrupted` | boolean | null |  | Interrupted |
| `customMetadata` | Object (any) | null |  | Custommetadata |
| `usageMetadata` | `GenerateContentResponseUsageMetadata-Input` | null |  |  |
| `invocationId` | string |  | Invocationid |
| `author` | string | ✓ | Author |
| `actions` | `EventActions-Input` |  |  |
| `longRunningToolIds` | Array[string] | null |  | Longrunningtoolids |
| `branch` | string | null |  | Branch |
| `id` | string |  | Id |
| `timestamp` | number |  | Timestamp |


### Event-Output

Represents an event in a conversation between agents and users.

It is used to store the content of the conversation, as well as the actions
taken by the agents like function calls, etc.

Attributes:
  invocation_id: The invocation ID of the event.
  author: "user" or the name of the agent, indicating who appended the event
    to the session.
  actions: The actions taken by the agent.
  long_running_tool_ids: The ids of the long running function calls.
  branch: The branch of the event.
  id: The unique identifier of the event.
  timestamp: The timestamp of the event.
  is_final_response: Whether the event is the final response of the agent.
  get_function_calls: Returns the function calls in the event.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `content` | `Content-Output` | null |  |  |
| `groundingMetadata` | `GroundingMetadata-Output` | null |  |  |
| `partial` | boolean | null |  | Partial |
| `turnComplete` | boolean | null |  | Turncomplete |
| `errorCode` | string | null |  | Errorcode |
| `errorMessage` | string | null |  | Errormessage |
| `interrupted` | boolean | null |  | Interrupted |
| `customMetadata` | Object (any) | null |  | Custommetadata |
| `usageMetadata` | `GenerateContentResponseUsageMetadata-Output` | null |  |  |
| `invocationId` | string |  | Invocationid |
| `author` | string | ✓ | Author |
| `actions` | `EventActions-Output` |  |  |
| `longRunningToolIds` | Array[string] | null |  | Longrunningtoolids |
| `branch` | string | null |  | Branch |
| `id` | string |  | Id |
| `timestamp` | number |  | Timestamp |


### EventActions-Input

Represents the actions attached to an event.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `skipSummarization` | boolean | null |  | Skipsummarization |
| `stateDelta` | Object (any) |  | Statedelta |
| `artifactDelta` | Object (any) |  | Artifactdelta |
| `transferToAgent` | string | null |  | Transfertoagent |
| `escalate` | boolean | null |  | Escalate |
| `requestedAuthConfigs` | Object (any) |  | Requestedauthconfigs |


### EventActions-Output

Represents the actions attached to an event.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `skipSummarization` | boolean | null |  | Skipsummarization |
| `stateDelta` | Object (any) |  | Statedelta |
| `artifactDelta` | Object (any) |  | Artifactdelta |
| `transferToAgent` | string | null |  | Transfertoagent |
| `escalate` | boolean | null |  | Escalate |
| `requestedAuthConfigs` | Object (any) |  | Requestedauthconfigs |


### ExecutableCode

Code generated by the model that is meant to be executed, and the result returned to the model.

Generated when using the [FunctionDeclaration] tool and
[FunctionCallingConfig] mode is set to [Mode.CODE].

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `code` | string | null |  | Required. The code to be executed. |
| `language` | `Language` | null |  | Required. Programming language of the `code`. |


### FileData

URI based data.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `displayName` | string | null |  | Optional. Display name of the file data. Used to provide a label or filename to distinguish file datas. It is not currently used in the Gemini GenerateContent calls. |
| `fileUri` | string | null |  | Required. URI. |
| `mimeType` | string | null |  | Required. The IANA standard MIME type of the source data. |


### FunctionCall

A function call.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | string | null |  | The unique id of the function call. If populated, the client to execute the
   `function_call` and return the response with the matching `id`. |
| `args` | Object (any) | null |  | Optional. The function parameters and values in JSON object format. See [FunctionDeclaration.parameters] for parameter details. |
| `name` | string | null |  | Required. The name of the function to call. Matches [FunctionDeclaration.name]. |


### FunctionResponse

A function response.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `willContinue` | boolean | null |  | Signals that function call continues, and more responses will be returned, turning the function call into a generator. Is only applicable to NON_BLOCKING function calls (see FunctionDeclaration.behavior for details), ignored otherwise. If false, the default, future responses will not be considered. Is only applicable to NON_BLOCKING function calls, is ignored otherwise. If set to false, future responses will not be considered. It is allowed to return empty `response` with `will_continue=False` to signal that the function call is finished. |
| `scheduling` | `FunctionResponseScheduling` | null |  | Specifies how the response should be scheduled in the conversation. Only applicable to NON_BLOCKING function calls, is ignored otherwise. Defaults to WHEN_IDLE. |
| `id` | string | null |  | Optional. The id of the function call this response is for. Populated by the client to match the corresponding function call `id`. |
| `name` | string | null |  | Required. The name of the function to call. Matches [FunctionDeclaration.name] and [FunctionCall.name]. |
| `response` | Object (any) | null |  | Required. The function response in JSON object format. Use "output" key to specify function output and "error" key to specify error details (if any). If "output" and "error" keys are not specified, then whole "response" is treated as function output. |


### FunctionResponseScheduling

Specifies how the response should be scheduled in the conversation.

**Type:** `string`

**Allowed Values:**

- `SCHEDULING_UNSPECIFIED`
- `SILENT`
- `WHEN_IDLE`
- `INTERRUPT`


### GenerateContentResponseUsageMetadata-Input

Usage metadata about response(s).

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `cacheTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities of the cached content in the request input. |
| `cachedContentTokenCount` | integer | null |  | Output only. Number of tokens in the cached part in the input (the cached content). |
| `candidatesTokenCount` | integer | null |  | Number of tokens in the response(s). |
| `candidatesTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities that were returned in the response. |
| `promptTokenCount` | integer | null |  | Number of tokens in the request. When `cached_content` is set, this is still the total effective prompt size meaning this includes the number of tokens in the cached content. |
| `promptTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities that were processed in the request input. |
| `thoughtsTokenCount` | integer | null |  | Output only. Number of tokens present in thoughts output. |
| `toolUsePromptTokenCount` | integer | null |  | Output only. Number of tokens present in tool-use prompt(s). |
| `toolUsePromptTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities that were processed for tool-use request inputs. |
| `totalTokenCount` | integer | null |  | Total token count for prompt, response candidates, and tool-use prompts (if present). |
| `trafficType` | `TrafficType` | null |  | Output only. Traffic type. This shows whether a request consumes Pay-As-You-Go or Provisioned Throughput quota. |


### GenerateContentResponseUsageMetadata-Output

Usage metadata about response(s).

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `cacheTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities of the cached content in the request input. |
| `cachedContentTokenCount` | integer | null |  | Output only. Number of tokens in the cached part in the input (the cached content). |
| `candidatesTokenCount` | integer | null |  | Number of tokens in the response(s). |
| `candidatesTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities that were returned in the response. |
| `promptTokenCount` | integer | null |  | Number of tokens in the request. When `cached_content` is set, this is still the total effective prompt size meaning this includes the number of tokens in the cached content. |
| `promptTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities that were processed in the request input. |
| `thoughtsTokenCount` | integer | null |  | Output only. Number of tokens present in thoughts output. |
| `toolUsePromptTokenCount` | integer | null |  | Output only. Number of tokens present in tool-use prompt(s). |
| `toolUsePromptTokensDetails` | Array[`ModalityTokenCount`] | null |  | Output only. List of modalities that were processed for tool-use request inputs. |
| `totalTokenCount` | integer | null |  | Total token count for prompt, response candidates, and tool-use prompts (if present). |
| `trafficType` | `TrafficType` | null |  | Output only. Traffic type. This shows whether a request consumes Pay-As-You-Go or Provisioned Throughput quota. |


### GroundingChunk-Input

Grounding chunk.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `retrievedContext` | `GroundingChunkRetrievedContext-Input` | null |  | Grounding chunk from context retrieved by the retrieval tools. |
| `web` | `GroundingChunkWeb` | null |  | Grounding chunk from the web. |


### GroundingChunk-Output

Grounding chunk.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `retrievedContext` | `GroundingChunkRetrievedContext-Output` | null |  | Grounding chunk from context retrieved by the retrieval tools. |
| `web` | `GroundingChunkWeb` | null |  | Grounding chunk from the web. |


### GroundingChunkRetrievedContext-Input

Chunk from context retrieved by the retrieval tools.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `ragChunk` | `RagChunk` | null |  | Additional context for the RAG retrieval result. This is only populated when using the RAG retrieval tool. |
| `text` | string | null |  | Text of the attribution. |
| `title` | string | null |  | Title of the attribution. |
| `uri` | string | null |  | URI reference of the attribution. |


### GroundingChunkRetrievedContext-Output

Chunk from context retrieved by the retrieval tools.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `ragChunk` | `RagChunk` | null |  | Additional context for the RAG retrieval result. This is only populated when using the RAG retrieval tool. |
| `text` | string | null |  | Text of the attribution. |
| `title` | string | null |  | Title of the attribution. |
| `uri` | string | null |  | URI reference of the attribution. |


### GroundingChunkWeb

Chunk from the web.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `domain` | string | null |  | Domain of the (original) URI. |
| `title` | string | null |  | Title of the chunk. |
| `uri` | string | null |  | URI reference of the chunk. |


### GroundingMetadata-Input

Metadata returned to client when grounding is enabled.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `groundingChunks` | Array[`GroundingChunk-Input`] | null |  | List of supporting references retrieved from specified grounding source. |
| `groundingSupports` | Array[`GroundingSupport`] | null |  | Optional. List of grounding support. |
| `retrievalMetadata` | `RetrievalMetadata` | null |  | Optional. Output only. Retrieval metadata. |
| `retrievalQueries` | Array[string] | null |  | Optional. Queries executed by the retrieval tools. |
| `searchEntryPoint` | `SearchEntryPoint` | null |  | Optional. Google search entry for the following-up web searches. |
| `webSearchQueries` | Array[string] | null |  | Optional. Web search queries for the following-up web search. |


### GroundingMetadata-Output

Metadata returned to client when grounding is enabled.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `groundingChunks` | Array[`GroundingChunk-Output`] | null |  | List of supporting references retrieved from specified grounding source. |
| `groundingSupports` | Array[`GroundingSupport`] | null |  | Optional. List of grounding support. |
| `retrievalMetadata` | `RetrievalMetadata` | null |  | Optional. Output only. Retrieval metadata. |
| `retrievalQueries` | Array[string] | null |  | Optional. Queries executed by the retrieval tools. |
| `searchEntryPoint` | `SearchEntryPoint` | null |  | Optional. Google search entry for the following-up web searches. |
| `webSearchQueries` | Array[string] | null |  | Optional. Web search queries for the following-up web search. |


### GroundingSupport

Grounding support.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `confidenceScores` | Array[number] | null |  | Confidence score of the support references. Ranges from 0 to 1. 1 is the most confident. This list must have the same size as the grounding_chunk_indices. |
| `groundingChunkIndices` | Array[integer] | null |  | A list of indices (into 'grounding_chunk') specifying the citations associated with the claim. For instance [1,3,4] means that grounding_chunk[1], grounding_chunk[3], grounding_chunk[4] are the retrieved content attributed to the claim. |
| `segment` | `Segment` | null |  | Segment of the content this support belongs to. |


### HTTPBase

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `SecuritySchemeType` |  |  |
| `description` | string | null |  | Description |
| `scheme` | string | ✓ | Scheme |

*Allows additional properties of any type*


### HTTPBearer

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `SecuritySchemeType` |  |  |
| `description` | string | null |  | Description |
| `scheme` | string |  | Scheme |
| `bearerFormat` | string | null |  | Bearerformat |

*Allows additional properties of any type*


### HTTPValidationError

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `detail` | Array[`ValidationError`] |  | Detail |


### HttpAuth

The credentials and metadata for HTTP authentication.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `scheme` | string | ✓ | Scheme |
| `credentials` | `HttpCredentials` | ✓ |  |

*Allows additional properties of any type*


### HttpCredentials

Represents the secret token value for HTTP authentication, like user name, password, oauth token, etc.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `username` | string | null |  | Username |
| `password` | string | null |  | Password |
| `token` | string | null |  | Token |

*Allows additional properties of any type*


### IntermediateData-Input

Container for intermediate data that an agent would generate as it responds with a final answer.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `toolUses` | Array[`FunctionCall`] |  | Tooluses |
| `intermediateResponses` | Array[array] |  | Intermediateresponses |


### IntermediateData-Output

Container for intermediate data that an agent would generate as it responds with a final answer.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `toolUses` | Array[`FunctionCall`] |  | Tooluses |
| `intermediateResponses` | Array[array] |  | Intermediateresponses |


### Invocation-Input

Represents a single invocation.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `invocationId` | string |  | Invocationid |
| `userContent` | `Content-Input` | ✓ |  |
| `finalResponse` | `Content-Input` | null |  |  |
| `intermediateData` | `IntermediateData-Input` | null |  |  |
| `creationTimestamp` | number |  | Creationtimestamp |


### Invocation-Output

Represents a single invocation.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `invocationId` | string |  | Invocationid |
| `userContent` | `Content-Output` | ✓ |  |
| `finalResponse` | `Content-Output` | null |  |  |
| `intermediateData` | `IntermediateData-Output` | null |  |  |
| `creationTimestamp` | number |  | Creationtimestamp |


### Language

Required. Programming language of the `code`.

**Type:** `string`

**Allowed Values:**

- `LANGUAGE_UNSPECIFIED`
- `PYTHON`


### MediaModality

Server content modalities.

**Type:** `string`

**Allowed Values:**

- `MODALITY_UNSPECIFIED`
- `TEXT`
- `IMAGE`
- `VIDEO`
- `AUDIO`
- `DOCUMENT`


### ModalityTokenCount

Represents token counting info for a single modality.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `modality` | `MediaModality` | null |  | The modality associated with this token count. |
| `tokenCount` | integer | null |  | Number of tokens. |


### OAuth2-Input

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `SecuritySchemeType` |  |  |
| `description` | string | null |  | Description |
| `flows` | `OAuthFlows` | ✓ |  |

*Allows additional properties of any type*


### OAuth2-Output

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `SecuritySchemeType` |  |  |
| `description` | string | null |  | Description |
| `flows` | `OAuthFlows` | ✓ |  |

*Allows additional properties of any type*


### OAuth2Auth

Represents credential value and its metadata for a OAuth2 credential.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `clientId` | string | null |  | Clientid |
| `clientSecret` | string | null |  | Clientsecret |
| `authUri` | string | null |  | Authuri |
| `state` | string | null |  | State |
| `redirectUri` | string | null |  | Redirecturi |
| `authResponseUri` | string | null |  | Authresponseuri |
| `authCode` | string | null |  | Authcode |
| `accessToken` | string | null |  | Accesstoken |
| `refreshToken` | string | null |  | Refreshtoken |
| `expiresAt` | integer | null |  | Expiresat |
| `expiresIn` | integer | null |  | Expiresin |

*Allows additional properties of any type*


### OAuthFlowAuthorizationCode

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `refreshUrl` | string | null |  | Refreshurl |
| `scopes` | Object (any) |  | Scopes |
| `authorizationUrl` | string | ✓ | Authorizationurl |
| `tokenUrl` | string | ✓ | Tokenurl |

*Allows additional properties of any type*


### OAuthFlowClientCredentials

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `refreshUrl` | string | null |  | Refreshurl |
| `scopes` | Object (any) |  | Scopes |
| `tokenUrl` | string | ✓ | Tokenurl |

*Allows additional properties of any type*


### OAuthFlowImplicit

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `refreshUrl` | string | null |  | Refreshurl |
| `scopes` | Object (any) |  | Scopes |
| `authorizationUrl` | string | ✓ | Authorizationurl |

*Allows additional properties of any type*


### OAuthFlowPassword

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `refreshUrl` | string | null |  | Refreshurl |
| `scopes` | Object (any) |  | Scopes |
| `tokenUrl` | string | ✓ | Tokenurl |

*Allows additional properties of any type*


### OAuthFlows

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `implicit` | `OAuthFlowImplicit` | null |  |  |
| `password` | `OAuthFlowPassword` | null |  |  |
| `clientCredentials` | `OAuthFlowClientCredentials` | null |  |  |
| `authorizationCode` | `OAuthFlowAuthorizationCode` | null |  |  |

*Allows additional properties of any type*


### OpenIdConnect

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `SecuritySchemeType` |  |  |
| `description` | string | null |  | Description |
| `openIdConnectUrl` | string | ✓ | Openidconnecturl |

*Allows additional properties of any type*


### OpenIdConnectWithConfig

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | `SecuritySchemeType` |  |  |
| `description` | string | null |  | Description |
| `authorization_endpoint` | string | ✓ | Authorization Endpoint |
| `token_endpoint` | string | ✓ | Token Endpoint |
| `userinfo_endpoint` | string | null |  | Userinfo Endpoint |
| `revocation_endpoint` | string | null |  | Revocation Endpoint |
| `token_endpoint_auth_methods_supported` | Array[string] | null |  | Token Endpoint Auth Methods Supported |
| `grant_types_supported` | Array[string] | null |  | Grant Types Supported |
| `scopes` | Array[string] | null |  | Scopes |

*Allows additional properties of any type*


### Outcome

Required. Outcome of the code execution.

**Type:** `string`

**Allowed Values:**

- `OUTCOME_UNSPECIFIED`
- `OUTCOME_OK`
- `OUTCOME_FAILED`
- `OUTCOME_DEADLINE_EXCEEDED`


### Part-Input

A datatype containing media content.

Exactly one field within a Part should be set, representing the specific type
of content being conveyed. Using multiple fields within the same `Part`
instance is considered invalid.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `videoMetadata` | `VideoMetadata` | null |  | Metadata for a given video. |
| `thought` | boolean | null |  | Indicates if the part is thought from the model. |
| `inlineData` | `Blob` | null |  | Optional. Inlined bytes data. |
| `fileData` | `FileData` | null |  | Optional. URI based data. |
| `thoughtSignature` | string | null |  | An opaque signature for the thought so it can be reused in subsequent requests. |
| `codeExecutionResult` | `CodeExecutionResult` | null |  | Optional. Result of executing the [ExecutableCode]. |
| `executableCode` | `ExecutableCode` | null |  | Optional. Code generated by the model that is meant to be executed. |
| `functionCall` | `FunctionCall` | null |  | Optional. A predicted [FunctionCall] returned from the model that contains a string representing the [FunctionDeclaration.name] with the parameters and their values. |
| `functionResponse` | `FunctionResponse` | null |  | Optional. The result output of a [FunctionCall] that contains a string representing the [FunctionDeclaration.name] and a structured JSON object containing any output from the function call. It is used as context to the model. |
| `text` | string | null |  | Optional. Text part (can be code). |


### Part-Output

A datatype containing media content.

Exactly one field within a Part should be set, representing the specific type
of content being conveyed. Using multiple fields within the same `Part`
instance is considered invalid.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `videoMetadata` | `VideoMetadata` | null |  | Metadata for a given video. |
| `thought` | boolean | null |  | Indicates if the part is thought from the model. |
| `inlineData` | `Blob` | null |  | Optional. Inlined bytes data. |
| `fileData` | `FileData` | null |  | Optional. URI based data. |
| `thoughtSignature` | string | null |  | An opaque signature for the thought so it can be reused in subsequent requests. |
| `codeExecutionResult` | `CodeExecutionResult` | null |  | Optional. Result of executing the [ExecutableCode]. |
| `executableCode` | `ExecutableCode` | null |  | Optional. Code generated by the model that is meant to be executed. |
| `functionCall` | `FunctionCall` | null |  | Optional. A predicted [FunctionCall] returned from the model that contains a string representing the [FunctionDeclaration.name] with the parameters and their values. |
| `functionResponse` | `FunctionResponse` | null |  | Optional. The result output of a [FunctionCall] that contains a string representing the [FunctionDeclaration.name] and a structured JSON object containing any output from the function call. It is used as context to the model. |
| `text` | string | null |  | Optional. Text part (can be code). |


### RagChunk

A RagChunk includes the content of a chunk of a RagFile, and associated metadata.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `pageSpan` | `RagChunkPageSpan` | null |  | If populated, represents where the chunk starts and ends in the document. |
| `text` | string | null |  | The content of the chunk. |


### RagChunkPageSpan

Represents where the chunk starts and ends in the document.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `firstPage` | integer | null |  | Page where chunk starts in the document. Inclusive. 1-indexed. |
| `lastPage` | integer | null |  | Page where chunk ends in the document. Inclusive. 1-indexed. |


### RetrievalMetadata

Metadata related to retrieval in the grounding flow.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `googleSearchDynamicRetrievalScore` | number | null |  | Optional. Score indicating how likely information from Google Search could help answer the prompt. The score is in the range `[0, 1]`, where 0 is the least likely and 1 is the most likely. This score is only populated when Google Search grounding and dynamic retrieval is enabled. It will be compared to the threshold to determine whether to trigger Google Search. |


### RunEvalRequest

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `evalIds` | Array[string] | ✓ | Evalids |
| `evalMetrics` | Array[`EvalMetric`] | ✓ | Evalmetrics |


### RunEvalResult

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `evalSetFile` | string | ✓ | Evalsetfile |
| `evalSetId` | string | ✓ | Evalsetid |
| `evalId` | string | ✓ | Evalid |
| `finalEvalStatus` | `EvalStatus` | ✓ |  |
| `evalMetricResults` | Array[array] | ✓ | This field is deprecated, use overall_eval_metric_results instead. |
| `overallEvalMetricResults` | Array[`EvalMetricResult`] | ✓ | Overallevalmetricresults |
| `evalMetricResultPerInvocation` | Array[`EvalMetricResultPerInvocation`] | ✓ | Evalmetricresultperinvocation |
| `userId` | string | ✓ | Userid |
| `sessionId` | string | ✓ | Sessionid |


### SearchEntryPoint

Google search entry point.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `renderedContent` | string | null |  | Optional. Web content snippet that can be embedded in a web page or an app webview. |
| `sdkBlob` | string | null |  | Optional. Base64 encoded JSON representing array of tuple. |


### SecuritySchemeType

**Type:** `string`

**Allowed Values:**

- `apiKey`
- `http`
- `oauth2`
- `openIdConnect`


### Segment

Segment of the content.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `endIndex` | integer | null |  | Output only. End index in the given Part, measured in bytes. Offset from the start of the Part, exclusive, starting at zero. |
| `partIndex` | integer | null |  | Output only. The index of a Part object within its parent Content object. |
| `startIndex` | integer | null |  | Output only. Start index in the given Part, measured in bytes. Offset from the start of the Part, inclusive, starting at zero. |
| `text` | string | null |  | Output only. The text corresponding to the segment from the response. |


### ServiceAccount

Represents Google Service Account configuration.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `serviceAccountCredential` | `ServiceAccountCredential` | null |  |  |
| `scopes` | Array[string] | ✓ | Scopes |
| `useDefaultCredential` | boolean | null |  | Usedefaultcredential |

*Allows additional properties of any type*


### ServiceAccountCredential

Represents Google Service Account configuration.

Attributes:
  type: The type should be "service_account".
  project_id: The project ID.
  private_key_id: The ID of the private key.
  private_key: The private key.
  client_email: The client email.
  client_id: The client ID.
  auth_uri: The authorization URI.
  token_uri: The token URI.
  auth_provider_x509_cert_url: URL for auth provider's X.509 cert.
  client_x509_cert_url: URL for the client's X.509 cert.
  universe_domain: The universe domain.

Example:

    config = ServiceAccountCredential(
        type_="service_account",
        project_id="your_project_id",
        private_key_id="your_private_key_id",
        private_key="-----BEGIN PRIVATE KEY-----...",
        client_email="...@....iam.gserviceaccount.com",
        client_id="your_client_id",
        auth_uri="https://accounts.google.com/o/oauth2/auth",
        token_uri="https://oauth2.googleapis.com/token",
        auth_provider_x509_cert_url="https://www.googleapis.com/oauth2/v1/certs",
        client_x509_cert_url="https://www.googleapis.com/robot/v1/metadata/x509/...",
        universe_domain="googleapis.com"
    )


    config = ServiceAccountConfig.model_construct(**{
        ...service account config dict
    })

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | string |  | Type |
| `projectId` | string | ✓ | Projectid |
| `privateKeyId` | string | ✓ | Privatekeyid |
| `privateKey` | string | ✓ | Privatekey |
| `clientEmail` | string | ✓ | Clientemail |
| `clientId` | string | ✓ | Clientid |
| `authUri` | string | ✓ | Authuri |
| `tokenUri` | string | ✓ | Tokenuri |
| `authProviderX509CertUrl` | string | ✓ | Authproviderx509Certurl |
| `clientX509CertUrl` | string | ✓ | Clientx509Certurl |
| `universeDomain` | string | ✓ | Universedomain |

*Allows additional properties of any type*


### Session

Represents a series of interactions between a user and agents.

Attributes:
  id: The unique identifier of the session.
  app_name: The name of the app.
  user_id: The id of the user.
  state: The state of the session.
  events: The events of the session, e.g. user input, model response, function
    call/response, etc.
  last_update_time: The last update time of the session.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | string | ✓ | Id |
| `appName` | string | ✓ | Appname |
| `userId` | string | ✓ | Userid |
| `state` | Object (any) |  | State |
| `events` | Array[`Event-Output`] |  | Events |
| `lastUpdateTime` | number |  | Lastupdatetime |


### SessionInput

Values that help initialize a Session.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `appName` | string | ✓ | Appname |
| `userId` | string | ✓ | Userid |
| `state` | Object (any) |  | State |


### TrafficType

Output only.

Traffic type. This shows whether a request consumes Pay-As-You-Go or
Provisioned Throughput quota.

**Type:** `string`

**Allowed Values:**

- `TRAFFIC_TYPE_UNSPECIFIED`
- `ON_DEMAND`
- `PROVISIONED_THROUGHPUT`


### ValidationError

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `loc` | Array[string | integer] | ✓ | Location |
| `msg` | string | ✓ | Message |
| `type` | string | ✓ | Error Type |


### VideoMetadata

Describes how the video in the Part should be used by the model.

**Type:** `object`

**Properties:**

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `fps` | number | null |  | The frame rate of the video sent to the model. If not specified, the
        default value will be 1.0. The fps range is (0.0, 24.0]. |
| `endOffset` | string | null |  | Optional. The end offset of the video. |
| `startOffset` | string | null |  | Optional. The start offset of the video. |


---

*Documentation generated from OpenAPI specification*
