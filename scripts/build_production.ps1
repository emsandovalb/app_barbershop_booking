<#
.SYNOPSIS
    Builds the production web PWA with the required --dart-define flags,
    refusing to build at all if the safety checks below fail.

.DESCRIPTION
    This exists because `flutter build web --release` on its own trusts
    whatever --dart-define flags you remember to type. Two past incidents
    this guards against:
      1. BUSINESS_SLUG omitted -> the compiled default was "jc-studio",
         so a forgotten flag silently shipped the wrong business's brand.
      2. A real KAPSO_API_KEY passed via --dart-define -> it compiles as
         a plain string into main.dart.js, trivially recoverable via
         view-source on the deployed PWA. There is no client-side Kapso
         integration left to use it (removed deliberately) — if this ever
         reappears, it means someone is re-adding the insecure pattern.

.PARAMETER BusinessSlug
    Required. The business slug this build is for, e.g. barberia-tres-amigos.

.PARAMETER ApiBaseUrl
    Optional. Only needed when the PWA and API are NOT served from the
    same origin. Omit when they share an origin (the client defaults to
    "$origin/api/v1").

.EXAMPLE
    ./scripts/build_production.ps1 -BusinessSlug barberia-tres-amigos

.EXAMPLE
    ./scripts/build_production.ps1 -BusinessSlug barberia-tres-amigos -ApiBaseUrl https://api.example.com/api/v1
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$BusinessSlug,

    [string]$ApiBaseUrl = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($BusinessSlug)) {
    Write-Error "BusinessSlug is required and cannot be blank. Example: -BusinessSlug barberia-tres-amigos"
    exit 1
}

# Defense in depth: refuse the build outright if a real Kapso key is
# sitting in the environment and someone tries to thread it through.
# (There's no code path left that reads KAPSO_API_KEY, but this catches
# the mistake before it's baked into a shipped bundle rather than after.)
if (-not [string]::IsNullOrWhiteSpace($env:KAPSO_API_KEY)) {
    Write-Error "KAPSO_API_KEY is set in the environment. Never pass a real API key into a client build via --dart-define — it becomes visible in main.dart.js. Unset it before building."
    exit 1
}

Write-Host "Building production web release for business slug '$BusinessSlug'..."
if ($ApiBaseUrl) {
    Write-Host "API base URL override: $ApiBaseUrl"
} else {
    Write-Host "No API_BASE_URL override — client will default to `$origin/api/v1 (same-origin deploy)."
}

# flutter.bat writes routine, non-fatal notices (e.g. its "Wasm dry run"
# compatibility notice) to stderr as part of a normal, successful build.
# With $ErrorActionPreference = 'Stop', PowerShell treats each such
# stderr line as a terminating error THE MOMENT stdout/stderr are merged
# or redirected (2>&1, *>, | in a pipeline, and — critically — this is
# exactly how CI/deploy log capture normally invokes a build script) —
# aborting before `flutter` even finishes, before its real exit code is
# known. Confirmed live: this script died on flutter's first stderr line
# under `*> file` redirection despite the build not having failed yet.
# Scoped to 'Continue' just for this call so only the real exit code
# (checked explicitly below) decides success or failure.
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    # NOT splatting an array (`@defines`) into `flutter` here: `flutter`
    # on Windows is `flutter.bat`, and PowerShell's array-splat to a
    # batch-file target silently drops arguments in some invocation
    # paths instead of raising an error — confirmed live: dart2js's own
    # logged command line was missing --dart-define entirely when built
    # this way, while the exact same flags typed directly on the
    # command line worked. Passing each flag as its own literal
    # argument avoids that failure mode.
    if ($ApiBaseUrl) {
        & flutter build web --release "--dart-define=BUSINESS_SLUG=$BusinessSlug" "--dart-define=API_BASE_URL=$ApiBaseUrl"
    } else {
        & flutter build web --release "--dart-define=BUSINESS_SLUG=$BusinessSlug"
    }
} finally {
    $ErrorActionPreference = $previousErrorActionPreference
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter build web failed (exit code $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host "Build complete: build/web" -ForegroundColor Green
