#!/bin/bash
unset HISTFILE; set +o history; # Prevent history file/memory pollution (Under observation)
set +H # Disable '!' history expansion for preventing errors when using ! marks in strings or sed (Alternative: "'!'")
set -euo pipefail # Strict mode (Ensures that execution stops at the slightest error)
trap 'debugger $LINENO "$BASH_COMMAND"' ERR # Debug Mode (Comment/Uncomment as needed)

# ⚙ CONFIGURATION (Monorepo user-definable variables, customizable via 'docs/.config')
declare -- BUILD_CORE="ls" # The Core name or system/namespace identifier (leave "ls" to contribute here; use your own initials for derivative forks)
declare -a BUILD_COPY=( "Embed" "Menu" "Modules" "ScriptResources" "Tool" "Utility" "LICENSE" ) # Copy whitelist: Monorepo root items to mirror (⚠ Removing items here won't auto-purge them in the Pack!)
declare -a BUILD_SYNC=( "Embed" "Menu" "Modules" "ScriptResources" "Tool" "Utility" ) # Sync whitelist: Pack folders for tracking/cleaning (⚠ DO NOT WORK HERE! Unlisted ones, e.g. ".git" or "docs" will stay untouched, though. But...)
declare -A BUILD_VARS=( [DEP]="ScriptDeps" [VER]="ScriptVersion" [BLD]="ScriptBuild" [STG]="ScriptStage" [TAR]="ScriptTarget" [DSC]="ScriptDesc" ) # Script header variables (if "ScriptDeps" is present in a .lua file, it's considered a pack!)
declare -A BUILD_FORGE=( [BASE]="github.com" [BRAW]="raw.githubusercontent.com" [USER]="lost-scripts" [PREF]="git@github-lost-scripts" ) # URL, contentUrl, username, remotePrefix (SSH Alias), [MONO]="custom-repo" (optional, overrides USER)
declare -- BUILD_DISTDIR='${TARGET_DIR}/docs/.dist' # ZIP creation requires existing dir plus zip.exe/bzip2.dll in %ProgramFiles%\Git\usr\bin. Supports (via expander): '${res_path}/...' or '${TARGET_DIR}/...'
declare -- BUILD_PUBLISH=false # Whether the pack will be published or not (Requires that the pack has a repo and 'origin' remote)
declare -- BUILD_MOHOCCF="../../Moho Pro"
declare -- BUILD_WEBPATH="../.github.io/content/scripts" # Static Site Proyect content directory (Empty to disable)
declare -- BUILD_WEBFILE="index" # Default filename expected by the Static Site Generator (E.g., index.md)
declare -- BUILD_WEBRSCS="assets" # Default directory for web resources
declare -- BUILD_DEBUGME=false # Or, alternatively, just run by: 'bash -x ./BUILDER.sh'
declare -a BUILD_PACKSWARN=( "READONLY!" "lost-scripts.github.io/other/read-only-repository" "79" "AUTO-GENERATED directory. Do NOT edit synced folders content manually! (Git/Unsynced folders are safe, but saving work here is still discouraged)." ) # Read-only admonition ("FILENAME" "URL" "ICON" "DESC" "NOTE")
declare -a BUILD_ZIPIGNORE=( "README.md" "READONLY!.url" "LICENSE" "*/LOG.*" "docs" "docs/*" ) # Files that won't be added to the .zip archive
declare -a BUILD_CATIGNORE=( "DRAFT" "HIDDEN" "PRIVATE" "LEGACY" ) # Script packs filter for the catalog (In base of ScriptStage variable)
declare -a BUILD_IGNOREPFX=( "__*" ".[!.]*/" ) # Ignore prefix entries (e.g., __wtvr, .arc, .priv)
declare -a BUILD_IGNORESFX=( "*.log" "*.log.*" "*.off" "*.off.*" "*.old" "*.old.*" "*.tmp" "*.tmp.*" "*.trash" "*.trash.*" ) # Ignore suffix entries (e.g., my_files.old.lua, my_folder.DIS)
declare -a BUILD_IGNOREFIL=( "[._]info.*" "[._]notes.*" "[._]todo.*" "[._]temp.*" "[._]tmp.*" ) # Ignore file entries (e.g., _info.txt, .TEMP.lua)
declare -a BUILD_UNIGNORED=( "_app" ) # Unignore entries (e.g., _keep, __wtvr, _etc)
declare -A BUILD_ASSIST=( ["ENABLE"]=true # Auto-assist different tasks (ENABLE (Master switch): true/false, FEATURE: true/false or ".lua .md" for filtering )
	["BLDSTAMP"]=false # ScriptBuild variable update/amend when needed, e.g.: true (always) / false (disabled) / ".lua .json" (filter)
	["DOCSCOOK"]=true  # Markdown file generation/cooking: set to true so it runs globally for MD tasks without filter
	["SYMLINKS"]=false # Symlink (re)creation at `$BUILD_MOHOCCF` for allowing listed items in .config `$BUILD_SYMLINKS` to be loaded by Moho even in production mode!
)

# 🔒 CONFIGURATION CONSTANTS (Uncustomizable/Runtime variables for path resolutions, patterns, etc. )
declare -Ar INFO=( [NAME]="Lost Builder®" [VERSION]="1.9.7" [CREATOR]="Rai López" [DESC]="Lost Scripts™ Project's Builder and Development Helper" [RUNTIME]=$(date +"%Y%m%d-%H%M"))
declare -r  MONODIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # The anchor: The Monorepo root directory itself
declare -r  FILENAME=$(basename "${BASH_SOURCE[0]}")
declare --  CANCELLED=false; 
declare -A  VAREXS=( [S]='s/.*=[[:space:]]*\(['"'"'"]\)\(.*\)\1\( --.*\)*$/\2/p' [A]='s/[^=]*=[[:space:]]*//; s/[^"'\'']*["'\'']\([^"'\'']*\)["'\'']/\1 /g' ) # Script header variable extractors
declare -A  REPORT=( [DUR]=0 [TOT]=0 [LOC]=0 [PUB]=0 [ISS]=0)
declare --  T_r='\e[31m'; T_R='\e[1;31m'; T_g='\e[32m'; T_y='\e[33m'; T_b='\e[34m'; T_B='\e[1;34m'; T_p='\e[35m'; T_c='\e[36m'; T_w='\e[37m'; T_d='\e[2m'; T_D='\e[1;2m'; T_i='\e[3m'; T_I='\e[3m\e[1m'; T_S='\e[1m'; T_u='\e[4m'; T_U='\e[1;4m'; T__='\e[9m'; T_F='\e['; T_N='\e[0m' # Text styling colors and formats
declare --  ICON_DL_B64="PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj48cGF0aCBmaWxsPSIjZWVlIiBkPSJNMjg4IDMyYTMyIDMyIDAgMSAwLTY0IDB2MjQzbC03My03NGEzMiAzMiAwIDAgMC00NiA0NmwxMjggMTI4YzEzIDEyIDMzIDEyIDQ2IDBsMTI4LTEyOGEzMiAzMiAwIDAgMC00Ni00NmwtNzMgNzRWMzJ6TTY0IDM1MmMtMzUgMC02NCAyOS02NCA2NHYzMmMwIDM1IDI5IDY0IDY0IDY0aDM4NGMzNSAwIDY0LTI5IDY0LTY0di0zMmMwLTM1LTI5LTY0LTY0LTY0SDM0N2wtNDYgNDVhNjQgNjQgMCAwIDEtOTAgMGwtNDUtNDVINjR6bTM2OCA1NmEyNCAyNCAwIDEgMSAwIDQ4IDI0IDI0IDAgMSAxIDAtNDh6Ii8+PC9zdmc+"

# 🐞 DEBUGGER (⚠ Slow!): Log the entire process with timestamps in a namesake file
if [ "$BUILD_DEBUGME" = true ]; then
	export PS4='+ $(date "+%s.%N") ('"$FILENAME"':$LINENO): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; exec 2> "${FILENAME}.log"; set -x 
fi

# 🛠️ HELPER FUNCTIONS
assister() { # ASSIST's assistant to convert feature flags or extensions into grep arguments: feature ($1, str)
	local feature_value="$1"
	if [[ "$feature_value" == "true" ]]; then # Scenario A: If "true", we look for any text/code file extension (2 to 5 alphanumeric chars)
		echo "-e" "\.[a-zA-Z0-9]\{2,5\}$"
	else # Scenario B: Custom extensions mapped to grep patterns
		for ext in $feature_value; do echo "-e" "$(echo "$ext" | sed 's/^\./\\./')$"; done
	fi
} # USAGE: assister "${BUILD_ASSIST[BLDSTAMP]}"

debugger(){ # Debug Mode helper for catching errors before closing
	local ec=$?; set +e # Capture the error code before it's lost; Prevent debugger from crashing if something goes wrong during printing
	if [ "$ec" -eq 130 ] && [ "$CANCELLED" = true ]; then echo -e "--- 🛑 ${T_g}ABORTED (Safely):${T_N} Task interrupted by user. Restarting... \n"; exec bash "$0"; fi
	echo -ne "--- ❌ ${T_R}ERROR @ line $1:${T_N} $2 (EC: $ec) ${T_d}(Press any key to exit) ${T_N}"; read -n 1 -s && exit $ec
} # USAGE: unattended (to be used by trap)

expander() { # Expands variables within a string: str ($1)
	local input="$1"
	if [[ "$input" =~ (\$\(|\`|\||;) ]]; then # Minimal Security check: Block command substitution $( ) or ` `
		echo -e "    ❌ ${T_R}ERROR (expander):${T_N} Unexpected character(s) in: $input" >&2; return 1
	fi
	eval echo \"$input\" # Re-evaluates the string to resolve internal variables
} # USAGE: expander "$BUILD_DISTDIR"

filenamer() { # Ensure a valid filename or return a fallback: input ($1), fallback ($2, optional)
	local input="${1:-}"; local fallback="${2:-Unnamed}"; local cleaned="${input//[<>:\"\/\\|?*]/}"
	echo "${cleaned:-$fallback}"
} # USAGE: filenamer "$FILENAME" "Fallback"

admonisher() { # Generate a native Windows .url reminder/admonition
	local dir="$1"; local name="$2"; local url="${3:-}"; local icon="${4:-}"; local desc="${5:-}"; local note="${6:-}"
	local url_clean="${url#https://}"; url_clean="${url_clean#http://}"
	[ -d "${dir}" ] || return 1
	printf '[InternetShortcut]\nURL=https://%s\nIconIndex=%s\nIconFile=C:\\Windows\\system32\\imageres.dll\n[{5CBF2787-48CF-4208-B90E-EE5E5D420294}]\nProp21=31,%s' "${url_clean}" "${icon}" "${desc}" > "${dir}/${name}.url"
} # USAGE: admonisher "$TARGET_DIR" "READONLY!" "https://lost-scripts.github.io/other/warning/" "230" "Description text..."

zipper() { # .ZIP packaging function: id ($1), source ($2), dist_path ($3), reset ($4, optional)
	! command -v zip >/dev/null 2>&1 && return
	local id="$1"; local source="$2"; local rel_dist="$3"; local reset="${4:-false}" 
	[[ -z "$rel_dist" ]] && return 1; [[ ! -d "$rel_dist" ]] && return 0 
	local abs_zip_out=$(readlink -f "${rel_dist}/${id}.zip") # Setup paths (Internal resolution)
	(
		cd "$source" || exit
		local targets=( * ); [[ ! -e "${targets[0]}" ]] && targets=() 
		if [[ ${#targets[@]} -gt 0 ]]; then
			local exclude_args=(-x ".git*" "__*" "*/__*" "${BUILD_PACKSWARN[0]}" "ScriptResources/$id/docs*" "ScriptResources/$id/docs*")
			for p in "${BUILD_ZIPIGNORE[@]}"; do exclude_args+=("-x" "$p"); done 
			[ "$reset" = true ] && [ -f "$abs_zip_out" ] && rm "$abs_zip_out" 
			zip "-rq$([ "$reset" = true ] || echo "FS")" "$abs_zip_out" "${targets[@]}" "${exclude_args[@]}" 
		fi
	)
	[ -f "$abs_zip_out" ] && { echo "    🗜  ZIP updated: $rel_dist/${id}.zip"; return 0; } || return 1
} # USAGE: zipper "$script_id" "$TARGET_DIR" "${res_path}/.dist" true

# 🗂 CONFIGURATION CUSTOMIZATION CASCADE: Last one overwrites previous (root -> docs override)
[[ -f "$MONODIR/.config" ]] && source "$MONODIR/.config" 2>/dev/null
[[ -f "$MONODIR/docs/.config" ]] && source "$MONODIR/docs/.config" 2>/dev/null

# 🔬 CONFIGURATION SANITIZATION (Clean values for system safety)
BUILD_PACKSWARN[0]=$(filenamer "${BUILD_PACKSWARN[0]:-}" ".READONLY!") # Ensure the reminder has a valid filename

# 🛡️ FINAL VALIDATION & INIT (After loading possible overrides)
echo -e "--- 🛈  ${T_F}2;4m${INFO[NAME]} v${INFO[VERSION]} by ${INFO[CREATOR]} @ $(date +"%a %-H:%M")${T_N} ---"
shopt -s nocaseglob # Enable case-insensitivity for the remaining checks...
if [[ ! -d "$MONODIR/.git" || ! -d "$MONODIR/Menu" || ! -e "$MONODIR/Tool" ]]; then # Final validation with visual feedback
	echo -e "--- ❌ ${T_R}ERROR:${T_N} Valid Monorepo structure not found."
	echo -e "--- ⚠  The Builder must be executed from the Monorepo root containing .git, Menu, Tool..."
	echo -ne "\n${T_S}Action aborted. Press any key to exit...${T_N}"; read -n 1 -s; exit 1
fi; shopt -u nocaseglob # ...and disable it to restore behavior!
cd "$MONODIR" || exit 1 # Place the terminal at the root of the project

# 💬 INTENT SELECTION: PUBLISH/SHELL/CANCEL?
echo -ne "--- ？ Publish to ${T_i}${BUILD_FORGE[BASE]}/${BUILD_FORGE[USER]}/$BUILD_CORE…${T_N} when applicable? (${T_S}Y${T_N}es/${T_S}N${T_N}o/${T_S}S${T_N}hell/${T_S}C${T_N}ancel): "; read -n 1 confirm; SECONDS=0
case "$confirm" in
	y|Y) PUBLISH=true; echo -e "\n--- 🎯 ${T_B}GOAL:${T_N} Build & ${T_S}Publish${T_N} ${T_d}(💡 'Ctrl+C' aborts at any time)${T_N}"; sleep 0.5 ;;
	n|N) PUBLISH=false; echo -e "\n--- 🎯 ${T_B}GOAL:${T_N} Build & ${T_S}Kept Local${T_N} ${T_d}(💡 'Ctrl+C' aborts at any time)${T_N}"; sleep 0.5 ;;
	s|S) echo -e "\n--- 💻 Entering Shell... ${T_d}(💡 Type 'exit' to return)${T_N}"; bash --login -i; exec bash "$0" ;;
	*)   echo -e "\n--- 🛑 CANCELLED ${T_d}(Or invalid input/click detected)${T_N}: Exiting..."; sleep 1.5; exit 0 ;;
esac
trap 'CANCELLED=true; echo -e "--- ✋ ${T_r}ABORTION REQUEST!${T_N} Finishing current task safely before aborting..."' SIGINT # Press 'Ctrl+C' executes the function that activates the flag

# 0. 🚜 PREPARATION & HARVEST
CORE_DEST="../$BUILD_CORE" # The Core pack destination folder
CORE_DOCS=$(find "./ScriptResources/$BUILD_CORE" -maxdepth 1 -type d -iname "*docs*" -print -quit 2>/dev/null)
CORE_WRITE=$([[ -n "$CORE_DOCS" ]] && echo "$CORE_DOCS/WRITEME.md" || echo "") # The Core README.md source file
MONOREPO="${BUILD_FORGE[MONO]:-${BUILD_FORGE[USER]}}" # CUSTOM or USER (Same name as user by default)
MONO_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "0000000")
MONO_MSG=$(git log -1 --pretty=%B 2>/dev/null | tr -d '\r' | head -n 1 || echo "Initial state (no commits yet)") # Last commit message, if any, for context
MONO_READ="./docs/README.md"
URL_BASE="https://${BUILD_FORGE[BASE]}/${BUILD_FORGE[USER]}"
URL_RAW="https://${BUILD_FORGE[BRAW]}/${BUILD_FORGE[USER]}"
URL_RAW_CORE="${URL_RAW}/${BUILD_CORE}/main/ScriptResources/${BUILD_CORE}"
URL_RAW_MONO="https://${BUILD_FORGE[BRAW]}/${BUILD_FORGE[USER]}/${MONOREPO}/main"
MD_CATALOG=""; MD_CATASTART='<!-- CATALOG_START -->'; MD_CATAEND='<!-- CATALOG_END -->'; MD_CATADATA=$(mktemp)
MD_STARRED=""; MD_STARSTART="<!-- STARRED_START -->"; MD_STAREND="<!-- STARRED_END -->"; MD_STARDATA=""
IGNORE=( "${BUILD_IGNOREPFX[@]}" "${BUILD_IGNORESFX[@]}" "${BUILD_IGNOREFIL[@]}" )
IGNORE_ARGS=(); UNIGNORE_ARGS=()
UPDATED_WORKSP=false; UPDATED_COMMIT=false

if [[ -f "$CORE_WRITE" ]]; then MD_STARDATA=$(head -n 25 "$CORE_WRITE" | grep "Starred:" | sed 's/.*\[\(.*\)\].*/\1/' | tr -d ' ' || true); fi # Starred item extraction

# 0.1 ⚡ PRELIMINARY TASKS/AUTOMATIONS (Initialization block)
if [[ "${BUILD_ASSIST[ENABLE]}" == "true" ]] && [[ "${BUILD_ASSIST[BLDSTAMP]}" != "false" ]]; then # Level 1: Quick Security Filter (Master is on; feature is not disabled)
	if [[ "${BUILD_ASSIST[BLDSTAMP]}" == "true" || " ${BUILD_ASSIST[BLDSTAMP]} " == *" .lua "* ]]; then # Level 2: Feature is "true" (global) or the current file (assuming .lua) is in the filter (the spaces are to avoid false positives)
		echo -e "--- ⚡ Processing Monorepo Preliminary Tasks..."
		CURTIME=$(date +"%Y%m%d-%H%M"); COMTIME=$(git log -1 --format="%cd" --date=format:"%Y%m%d-%H%M" HEAD 2>/dev/null) # Contextual timestamp: current time for workspace; Commit time for HEAD
		
		while IFS= read -r file; do
			if [ -f "$file" ] && head -n 15 "$file" | grep -m 1 -q "${BUILD_VARS[BLD]}"; then
				# --- SCENARIO 1: Uncommitted human changes (Staged or Unstaged)
				if ! git diff --quiet HEAD -- "$file"; then
					area="Working Dir."; area_color="$T_r"
					if git diff --cached --name-only | grep -q "^$file$"; then area="Staging Area"; area_color="$T_g"; fi

					echo -e "    📝 ${BUILD_VARS[BLD]} UPD (${area_color}$area${T_N}): $file"
					sed -i "1,15s/\(${BUILD_VARS[BLD]}[[:space:]]*=[[:space:]]*[\"']\)[0-9]\{8\}[-_.]\?[0-9]\{4\}/\1$CURTIME/" "$file" # Or `[0-9]\{8\}-[0-9]` for strict hyphened date format
					UPDATED_WORKSP=true

					if [ "$area" = "Staging Area" ]; then git add "$file"; fi
					continue
				fi
				# --- SCENARIO 2: Already committed human changes
				if ! git diff --quiet HEAD~1..HEAD -- "$file" 2>/dev/null; then # Did the file change at all in the last commit? (Your core rule)
					if grep -q "${BUILD_VARS[BLD]} = \"$COMTIME\"" "$file"; then continue; fi # Idempotency guard: Skip if file already carries the identical commit timestamp (kills 'Restart' loop)

					echo -e "    📝 ${BUILD_VARS[BLD]} UPD (${T_y}Commit Amend${T_N}): $file"
					sed -i "1,15s/\(${BUILD_VARS[BLD]}[[:space:]]*=[[:space:]]*[\"']\)[0-9]\{8\}[-_.]\?[0-9]\{4\}/\1$COMTIME/" "$file" # Or `[0-9]\{8\}-[0-9]` for strict hyphened date format
					git add "$file" # NEW: Stage the script amendment before the amend
					UPDATED_COMMIT=true
				fi
			fi
		done < <( { git diff --name-only HEAD; git diff-tree --no-commit-id --name-only -r HEAD; } | grep $(assister "${BUILD_ASSIST[BLDSTAMP]}") | sort -u ) # Pass the function output directly as arguments to grep using $(...)

		# 📟 Final execution of Git adjustments based on what actually changed
		if [ "$CANCELLED" = true ]; then echo -e "--- 🛑 ${T_g}ABORTED (Safely):${T_N} Workspace updated but Git history untouched. Restarting... \n"; exec bash "$0"; fi # Cancel checkpoint 1
		if [ "$UPDATED_COMMIT" = true ]; then
			ORIG_AUTH_DATE=$(git log -1 --format="%ad" HEAD); ORIG_COMM_DATE=$(git log -1 --format="%cd" HEAD)
			GIT_AUTHOR_DATE="$ORIG_AUTH_DATE" GIT_COMMITTER_DATE="$ORIG_COMM_DATE" git commit --amend --no-edit >/dev/null 2>&1 # NOTE/TODO: Global --amend in Scenario 2 will absorb Scenario 1 staged files. If strict isolation is needed, temporarily unstage them before amending or evaluate implementing a temporary unstage/restage logic
		fi
		# 📣 Unified terminal notification
		[ "$UPDATED_COMMIT" = true ] && updated_notif="history synchronized"
		[ "$UPDATED_WORKSP" = true ] && { [ -n "$updated_notif" ] && updated_notif+=' & '; updated_notif+='workspace updated'; }
		[ -n "$updated_notif" ] && echo -e "    ✅ Monorepo $updated_notif smoothly!"
	fi
fi

# 0.2 📁 RESOLVE CUSTOM CONTENT FOLDER PATH (Supports absolute or relative paths)
MOHO_TARGET_DIR=""
if [[ -n "${BUILD_MOHOCCF:-}" ]]; then
	[[ "$BUILD_MOHOCCF" == /* || "$BUILD_MOHOCCF" =~ ^[A-Za-z]: ]] && MOHO_REAL_SCRIPTS="$BUILD_MOHOCCF" || MOHO_REAL_SCRIPTS="$(cd "$(dirname "$0")/$BUILD_MOHOCCF" 2>/dev/null && pwd || echo "")" # Resolve absolute or relative path into MOHO_REAL_SCRIPTS

	if [[ -d "${MOHO_REAL_SCRIPTS}/Scripts" && ! -L "${MOHO_REAL_SCRIPTS}/Scripts" ]]; then # Strict structural evaluation to avoid emulation or link-crossing bypasses
		MOHO_TARGET_DIR="$MOHO_REAL_SCRIPTS/Scripts"
	elif [[ -d "${MOHO_REAL_SCRIPTS}/Scripts.OFF" && ! -L "${MOHO_REAL_SCRIPTS}/Scripts.OFF" ]]; then
		MOHO_TARGET_DIR="$MOHO_REAL_SCRIPTS/Scripts.OFF"
	fi

	if [[ -n "$MOHO_REAL_SCRIPTS" && "${BUILD_ASSIST[ENABLE]}" == "true" && "${BUILD_ASSIST[SYMLINKS]}" == "true" ]]; then # PREEMPTIVE LAB LINK: Deploys background infrastructure if symlinks are enabled globally
		if [[ ! -e "${MOHO_REAL_SCRIPTS}/Scripts.OFF" ]]; then
			ln -s "$(realpath --relative-to="${MOHO_REAL_SCRIPTS}" "${MONODIR}")" "${MOHO_REAL_SCRIPTS}/Scripts.OFF" 2>/dev/null
		fi
	fi
fi

#: << 'SKIPPER' # If uncommented along with a `SKIPPER` tag bellow, everything in between will be ignored (Useful to speed up testing/debugging final steps)

# 1. 🔛 MIRRORING (Surgical deletion & robust copy + utra fast purge)
mkdir -p "$CORE_DEST"
# 1.1. 🔄 RESET & SYNC (Mirror recreation)
for item in "${BUILD_COPY[@]}"; do
	[[ ! -e "$item" ]] && continue
	target="$CORE_DEST/$(basename "$item")" # Remove file/folder in destination if it exists. We use basename to refer to the name at the root of $CORE_DEST
	rm -rf "$target" && cp -r "$item" "$target" # Deleting & fast/clean copying. TODO: Consider using rsync with --exclude patterns to avoid copying ignored stuff for removing them afterwards?
done
# 1.2. 🧹 IGNORED ITEMS PURGE (Surgical & Consistent with block 2.5)
for pat in "${IGNORE[@]}"; do # OR logic (Build the case-insensitive search expression for ignored patterns)
	if [[ "$pat" == */ ]]; then
		clean_pat="${pat%/}" # Remove any slash at the end of the pattern to get the clean name, but applying a directory-type filter
		[[ ${#IGNORE_ARGS[@]} -eq 0 ]] && IGNORE_ARGS+=( -type d -iname "$clean_pat" ) || IGNORE_ARGS+=( -o -type d -iname "$clean_pat" )
	else
		[[ ${#IGNORE_ARGS[@]} -eq 0 ]] && IGNORE_ARGS+=( -iname "$pat" ) || IGNORE_ARGS+=( -o -iname "$pat" )
	fi
done
for keep in "${BUILD_UNIGNORED[@]}"; do # NOT logic (Build the exclusion list for find: each item in UNIGNORED becomes '! -name/-iname item')
	UNIGNORE_ARGS+=( "!" "-iname" "$keep" )
done
BLD_SYNCVAL=($(for r in "${BUILD_SYNC[@]/#/$CORE_DEST/}"; do [[ -d "$r" ]] && echo "$r"; done))
[[ ${#BLD_SYNCVAL[@]} -gt 0 ]] && find "${BLD_SYNCVAL[@]}" \( "${IGNORE_ARGS[@]}" \) "${UNIGNORE_ARGS[@]}" -exec rm -rf {} + 2>/dev/null # Remove ignored/not-unignored items at once ONLY within synced folders (The parentheses are key to group the ORs before the NOT)
#[[ ${#IGNORE_ARGS[@]} -gt 0 ]] && find "$CORE_DEST" -maxdepth 1 \( "${IGNORE_ARGS[@]}" \) "${UNIGNORE_ARGS[@]}" -not -path "$CORE_DEST" -exec rm -rf {} + 2>/dev/null # OPTIONAL: ROOT-ONLY PURGE (Uncomment if root-level garbage (e.g. *.tmp) becomes an issue)
if [ "$CANCELLED" = true ]; then echo -e "--- 🛑 ${T_g}ABORTED (Safely):${T_N} Local mirror refreshed but script packs untouched. Restarting... \n"; exec bash "$0"; fi # Cancel checkpoint 2

# 2. 🧠 THE "SACRED LOGIC" (ID based)
echo -e "--- ✨ Distributing From Cleaned Mirror: ${T_i}$CORE_DEST${T_N}"
PACKS_TEMP=$(find "$CORE_DEST" -type f -name "*.lua" -exec grep -l "${BUILD_VARS[DEP]}" {} + | xargs -I {} basename {} .lua | grep -v "^${BUILD_CORE}$" | sort -u); SUB_EC=$? # Generate the "Sacred ID List" looking for ScriptDeps in *.lua; Capture error code
PACKS="$PACKS_TEMP $BUILD_CORE" # The final list (first the packs, and lastly, the Core)
if [ "$CANCELLED" = true ] || [ $SUB_EC -eq 130 ]; then echo -e "--- 🛑 ${T_g}ABORTED (Safely):${T_N} Local mirror synced but packs processing cancelled. Restarting... \n"; exec bash "$0"; fi # Cancel checkpoint 3

for script_id in $PACKS; do
	if [ "$CANCELLED" = true ]; then echo -e "--- 🛑 ${T_g}ABORTED (Safely):${T_N} Previous packs built cleanly; remaining packs skipped. Restarting... \n"; exec bash "$0"; fi # Cancel checkpoint 4
	# --- 🔀 2.1. PATH CONFIGURATION & MOVEMENT
	if [[ "$script_id" == "$BUILD_CORE" ]]; then
		TARGET_DIR="$CORE_DEST"
		echo -e "📦 Finalizing Core: ${T_u}$script_id${T_N}"
	else
		TARGET_DIR="../$script_id"
		echo -e "📦 Processing pack: ${T_u}$script_id${T_N}"
		mkdir -p "$TARGET_DIR"

		# --- 🖇 CHECK IF SYMLINKING IS REQUESTED FOR THIS PACK
		link_this_pack=false
		if [[ "${BUILD_ASSIST[ENABLE]}" == "true" && "${BUILD_ASSIST[SYMLINKS]}" == "true" ]]; then
			if [[ " ${BUILD_SYMLINKS[@]} " == *"${script_id}"* ]]; then # Direct check against your clean config list
				link_this_pack=true
			fi
		fi

		# --- 🔽 2.1a MOVE NORMAL PACKS COMPONENT FILES: Match the script base name (excluding ScriptResources to handle that separately) with any extension or High-DPI suffix while strictly avoiding shared global directories
		find "$CORE_DEST" -type f -not -path "*/ScriptResources/*" -not -path "*/Utility/*" -not -path "*/Modules/*" \( -name "${script_id}.*" -o -name "${script_id}@*" \) | while read -r file; do
			rel_path=$(dirname "${file#$CORE_DEST/}")
			mkdir -p "$TARGET_DIR/$rel_path"
			mv "$file" "$TARGET_DIR/$rel_path/"

			# 🖇 SYMLINKER INTEGRATION: "Free" per-file processing
			if [ "$link_this_pack" = true ] && [[ -n "$MOHO_TARGET_DIR" ]]; then
				b_name=$(basename "$file"); dst_file="$MOHO_TARGET_DIR/$rel_path/$b_name"; final_src="$TARGET_DIR/$rel_path/$b_name"

				if [[ ! -e "$dst_file" || -L "$dst_file" ]]; then # SAFETY CHECK: Only proceed if target does not exist OR is strictly a symlink
					rm -f "$dst_file"; mkdir -p "$(dirname "$dst_file")"; ln -s "$(realpath --relative-to="$(dirname "$dst_file")" "$final_src")" "$dst_file"
				else
					echo -e "    ⚠️  ${T_y}WARNING (Skipped symlink):${T_N} Real file exists at: ${T_d}Scripts/${dst_file#$MOHO_TARGET_DIR/}${T_N}"
				fi
			fi
		done

		# --- ⏬ 2.1b MOVE NORMAL PACKS RESOURCES
		if [ -d "$CORE_DEST/ScriptResources/$script_id" ]; then
			mkdir -p "$TARGET_DIR/ScriptResources"
			rm -rf "$TARGET_DIR/ScriptResources/$script_id"
			mv "$CORE_DEST/ScriptResources/$script_id" "$TARGET_DIR/ScriptResources/"

			# 🖇 SYMLINKER INTEGRATION: "Free" folder resource linking
			if [ "$link_this_pack" = true ] && [[ -n "$MOHO_TARGET_DIR" ]]; then
				dst_res="$MOHO_TARGET_DIR/ScriptResources/$script_id"; final_res="$TARGET_DIR/ScriptResources/$script_id"
				
				if [[ ! -e "$dst_res" || -L "$dst_res" ]]; then # SAFETY CHECK: Protect real resource folders
					rm -rf "$dst_res"; mkdir -p "$MOHO_TARGET_DIR/ScriptResources"; ln -s "$(realpath --relative-to="$MOHO_TARGET_DIR/ScriptResources" "$final_res")" "$dst_res"
				else
					echo -e "    ⚠️  ${T_y}WARNING (Skipped symlink):${T_N} Real dir. exists at: ${T_d}Scripts/${dst_res#$MOHO_TARGET_DIR/}${T_N}"
				fi
			fi
		fi
	fi

	# --- ♌ 2.1c SCRIPT RESOURCES PATH RESOLUTION
	res_path=$(find ./ScriptResources -maxdepth 1 -type d -name "$script_id" -print -quit) # Use -maxdepth 2 or a customizable variable if nested folders are needed
	DOCSDIR=$(find "$res_path" -maxdepth 1 -type d -iname "*docs*" -print -quit 2> /dev/null) || DOCSDIR="" # Only assign DOCSDIR if a _docs or docs folder exists in resources, otherwise reset to empty

	# --- 🔙 2.1d SAFETY MARK (Ensure security mark on ALL packs if defined!)
	if [[ -f "$TARGET_DIR/${BUILD_PACKSWARN[0]}.url" ]]; then :; else
		admonisher "$TARGET_DIR" "${BUILD_PACKSWARN[@]}"
	fi

	# --- 🔍 2.2. INJECT DEPENDENCIES & METADATA EXTRACTION (The "Smart Search" Logic)
	header="" v_name="" v_ver="0.0.0" v_tar="" v_stg="STABLE" v_dsc="" v_dsc_plain="" v_skip=false # Atomic reset
	if [[ "$script_id" == "$BUILD_CORE" ]]; then
		MASTER_CORE="./Utility/ls_utilities.lua"
		if [ -f "$MASTER_CORE" ]; then
			header=$(head -n 25 "$MASTER_CORE" | tr -d '\r')
			echo "    ℹ️  Core metadata sourced from: $MASTER_CORE"
		fi
	else
		while read -r main_file; do # Look for ALL namesake script files in TARGET_DIR
			temp_header=$(head -n 25 "$main_file" | tr -d '\r') # Check the header to see if it's the one that contains the info
			if echo "$temp_header" | grep -qE "${BUILD_VARS[DEP]}|${BUILD_VARS[VER]}"; then # Guard clause: if there's ScriptDeps/ScriptVersion, it's main file
				header="$temp_header"
				deps=$(echo "$header" | grep "${BUILD_VARS[DEP]}" | sed -e "${VAREXS[A]}") # Dependency injection: If we get here, we have found the "parent file" (the ID with info)
				for dep in $deps; do
					target_dep=$(echo "$dep" | tr -d '{}," ' | tr '\\' '/') # Complete removal of unwanted characters
					if [[ -n "$target_dep" && "$target_dep" != "/" ]]; then # Verify that it's not an empty string or an orphaned bar
						if [ -f "./$target_dep" ]; then
							mkdir -p "$TARGET_DIR/$(dirname "$target_dep")"
							cp "./$target_dep" "$TARGET_DIR/$target_dep"
							echo "    ✅ Dependency injected: $target_dep"
						else
							echo -e "    ❎ ${T_R}Missing dependency:${T_N} ./$target_dep"; ((++REPORT[ISS])) # Just in case there in the path or a renamed a dependency
						fi
					fi
				done
				break # Main file found; exiting the loop...
			fi
		done < <(find "$TARGET_DIR" -name "${script_id}.lua" -type f)
	fi

	# --- 🥢 2.3. UNIVERSAL METADATA COLLECTION & TREATMENT (Customhouse)
	v_name=$(echo "$script_id" | sed 's/ls_//g; s/_/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
	v_name="${v_name:-${script_id:-Unknown}}"; [[ "$script_id" == "$BUILD_CORE" ]] && v_name="${v_name^^}"
	if [[ -n "$header" ]]; then # Extract everything in one go so it's available afterwards
		v_ver=$(echo "$header" | grep "${BUILD_VARS[VER]}" | sed -n "${VAREXS[S]}") || v_ver="0.0.0"
		v_stg=$(echo "$header" | grep "${BUILD_VARS[STG]}" | sed -n "${VAREXS[S]}") || v_stg="STABLE"; v_stg="${v_stg// /}" # Clean spaces for safety reasons
		v_bld=$(echo "$header" | grep "${BUILD_VARS[BLD]}" | sed -n "${VAREXS[S]}") || v_bld="N/D"
		v_tar=$(echo "$header" | grep "${BUILD_VARS[TAR]}" | sed -n "${VAREXS[S]}") || v_tar=""
		v_dsc=$(echo "$header" | grep "${BUILD_VARS[DSC]}" | sed -n "${VAREXS[S]}") || v_dsc=""
	fi

	if [[ -z "$v_dsc" ]]; then # Description fallback
		if [[ "$script_id" == "$BUILD_CORE" ]]; then
			v_dsc="Essential shared resources and core modules required for the <a href='https://lost-scripts.github.io/' title='Go to Lost Scripts&trade; website...'>Lost Scripts</a>&trade; project to work with <a href='https://moho.lostmarble.com/' title='Go to Moho&reg; homepage...'>MOHO</a> Animation Software (NOT YET AVAILABLE)."
		else
			v_dsc="Lost Script <em>$v_name</em> for <a href='https://moho.lostmarble.com/' title='Go to Moho&reg; homepage...'>MOHO</a> Animation Software."
		fi
	fi
	v_dsc_plain=$(echo "$v_dsc" | sed 's/<[^>]*>//g') # Provide an HTML-free description
	v_stg_warn="$v_ver"; [[ "$v_stg" != "STABLE" ]] && v_stg_warn="${v_ver}-${v_stg}" # E.g. 1.2.0-BETA

	# --- 🚦 2.3a GLOBAL EXCLUSION FILTER
	for skip in "${BUILD_CATIGNORE[@]}"; do
		if [[ "$v_stg" == "$skip" ]]; then
			#if [[ "$script_id" == "$BUILD_CORE" ]]; then
				#v_skip=false # Core exception: It's never skipped (TODO: Uncomment everything to revert when Core is ready!) 
			#else
				v_skip=true
			#fi
			break
		fi
	done

	# --- 🖼️ 2.3b INTELLIGENT ICON LOGIC (Hybrid GitHub/HUGO Support)
	ASSETS_DIR="$DOCSDIR/$BUILD_WEBRSCS"
	ICON_MAIN="${URL_RAW_MONO}/ScriptResources/${script_id}/docs/$BUILD_WEBRSCS/icon_unk.png"
	ICON_DARK="${URL_RAW_MONO}/ScriptResources/${script_id}/docs/$BUILD_WEBRSCS/icon_unk_dark.png"
	ICON_LIGHT="${URL_RAW_MONO}/ScriptResources/${script_id}/docs/$BUILD_WEBRSCS/icon_unk_light.png"
	ICON_DL="https://img.shields.io/badge/-%20-blue?style=flat&logo=data:image/svg%2bxml;base64,${ICON_DL_B64}&logoColor=white"
	if [ -f "$ASSETS_DIR/icon.png" ]; then # Check for the presence of package-specific icons
		ICON_MAIN="${URL_RAW_MONO}/ScriptResources/${script_id}/docs/$BUILD_WEBRSCS/icon.png" # The default icon will always be the original Moho icon
		[ -f "$ASSETS_DIR/icon_dark.png" ] && ICON_DARK="${URL_RAW_MONO}/ScriptResources/${script_id}/docs/$BUILD_WEBRSCS/icon_dark.png" || ICON_DARK="$ICON_MAIN" # Look for an optimized version for DARK, or fallback to the original
		[ -f "$ASSETS_DIR/icon_light.png" ] && ICON_LIGHT="${URL_RAW_MONO}/ScriptResources/${script_id}/docs/$BUILD_WEBRSCS/icon_light.png" || ICON_LIGHT="$ICON_MAIN" # Look for an optimized version for LIGHT, or fallback to the original
	fi
	PICTURE_TAG="<picture><source media='(prefers-color-scheme: dark)' srcset='${ICON_DARK}'><source media='(prefers-color-scheme: light)' srcset='${ICON_LIGHT}'><img src='${ICON_MAIN}' width='48' alt='Icon' class='colorize'></picture>"

	# --- 🔗 2.3c UNIVERSAL DOWNLOAD URL
	if git -C "$TARGET_DIR" remote get-url origin >/dev/null 2>&1; then # REMOTE SCENARIO: If there are version tags > latest Release, otherwise > GitHub's auto-generated ZIP
		if git -C "$TARGET_DIR" tag 2>/dev/null | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+'; then
			v_zip_url="https://${BUILD_FORGE[BASE]}/${BUILD_FORGE[USER]}/$script_id/releases/latest/download/${script_id}.zip"
		else
			v_zip_url="https://${BUILD_FORGE[BASE]}/${BUILD_FORGE[USER]}/$script_id/archive/refs/heads/main.zip"
		fi
	else # LOCAL SCENARIO (Fallback): Target the Core's latest release or, preferably, leave it empty
		v_zip_url="" # "https://${BUILD_FORGE[BASE]}/${BUILD_FORGE[USER]}/${BUILD_CORE}/releases/latest/download/${BUILD_CORE}.zip"
	fi

	# --- 🧹 2.4. FINALIZING + CLEANUP: Purge orphaned files and empty folders in target (Scan standard Monorepo folders and delete any not present in the source Monorepo)
	# echo -e "📦 Finalizing + Cleaning Package: $TARGET_DIR"
	for folder in "${BUILD_SYNC[@]}"; do
		[[ "$folder" == "docs" ]] && continue # Skip docs folder!
		if [ -d "$TARGET_DIR/$folder" ]; then
			find "$TARGET_DIR/$folder" -type f -not -path "*/_*" | while read -r target_file; do # Remove files that no longer exist in the source. Note: `-not -path "*/_*"` protects any file inside folders starting with _ (anywhere)
				rel_file="${target_file#$TARGET_DIR/}"
				if [[ "$(basename "$target_file")" == "${BUILD_PACKSWARN[0]}" ]]; then continue; fi # EXCEPTION: Preserve the security mark
				if [ ! -f "./$rel_file" ]; then rm "$target_file"; fi # RULE: Remove everything that is not in the source...
			done
			find "$TARGET_DIR/$folder" -type d -empty -not -path "*/.git*" -delete 2>/dev/null || true # Remove empty folders ONLY within synced folders
		fi
	done
	[ ! -f "$TARGET_DIR/LICENSE" ] && [ -f "$CORE_DEST/LICENSE" ] && cp "$CORE_DEST/LICENSE" "$TARGET_DIR/" || true # Ensure that there's a LICENSE

	# --- 🧩 2.5. PER-PACK MASTER DOCS COOKING & DISTRIBUTION (GitHub First Approach)
	if [[ "${BUILD_ASSIST[DOCSCOOK]}" != "false" || "$script_id" == "$BUILD_CORE" ]] && [[ -n "$DOCSDIR" && -f "$DOCSDIR/WRITEME.md" ]]; then # Nivel 1: Feature is not disabled (or it's the Core) and physical file exists
		WRITEME_SCR="$DOCSDIR/WRITEME.md"; WRITEME_TMP="$DOCSDIR/WRITEME.md.tmp"
		WRITE2READ="$DOCSDIR/README.tmp.md"; WRITE2WEBS="$DOCSDIR/${BUILD_WEBFILE}.tmp.md"
		H_START='<!-- HEADER_START -->'; H_END='<!-- HEADER_END -->'

		# A. 📄 HYBRID DOCS PROMOTION & FRONT MATTER DETECTION
		mkdir -p "$TARGET_DIR/docs"
		find "$DOCSDIR" -maxdepth 1 -not -name "WRITEME.md" -not -name "$(basename "$DOCSDIR")" "${IGNORE_ARGS[@]}" "${UNIGNORE_ARGS[@]}" -exec cp -r {} "$TARGET_DIR/docs/" \; 2>/dev/null || true # Copy filtered source assets & docs to preserve mirror Git history symmetry
		head -n 1 "$WRITEME_SCR" | grep -q '^---$' && HAS_FM=true || HAS_FM=false # Check if the raw source starts with a YAML front matter delimiter

		# B. ♨️ COOK THE MASTER TEMPLATE ONCE IN DISK (Going from most complete to simplest)
		cp -f "$WRITEME_SCR" "$WRITEME_TMP"

		if [ "$HAS_FM" = false ]; then # Ensure a bare minimum Front Matter baseline if it lacks one
			DEF_FM=$(printf -- "---\ntitle: \"%s\"\ndraft: true\n---\n" "$v_name")
			sed -i "1s/^/${DEF_FM}\n/" "$WRITEME_TMP"
		fi

		if grep -q "$H_START" "$WRITEME_TMP" && grep -q "$H_END" "$WRITEME_TMP"; then # Assets & Shields definitions and in-markers inject (Bulletproof generation)
			SAFE_TAR="${v_tar// /_}"
			DL_SHI="https://img.shields.io/github/downloads/${BUILD_FORGE[USER]}/${script_id}/total?logo=data:image/svg%2bxml;base64,${ICON_DL_B64}&color=blue&label=Download"
			RE_SHI="https://img.shields.io/github/v/release/${BUILD_FORGE[USER]}/${script_id}?logo=github&color=yellow&label=Release"
			TA_SHI="https://img.shields.io/badge/For-Moho_${SAFE_TAR}-orange"

			HEADER_HTML=$(cat <<- EOF
			<table id='top' width='100%' border='0'>
			    <tr>
			        <td align='center' valign='middle' width='96'>
			            <picture>
			                <source media='(prefers-color-scheme: dark)' srcset='${BUILD_WEBRSCS}/icon_dark.png'>
			                <source media='(prefers-color-scheme: light)' srcset='${BUILD_WEBRSCS}/icon_light.png'>
			                <img src='${BUILD_WEBRSCS}/icon.png' width='48' alt='Icon' title='${v_name}: ${v_dsc_plain}' class='colorize'>
			            </picture>
			        </td>
			        <td align='right' valign='middle' width='916' nowrap>
			            $( [[ "$v_stg" != "HIDDEN" ]] && echo "<a href='${URL_BASE}/${script_id}/releases/latest/download/${script_id}.zip' title='Download latest version...'><img src='${DL_SHI}' alt='Download'></a> " )
			            $( [[ "$v_stg" != "HIDDEN" ]] && echo "<a href='${URL_BASE}/${script_id}/releases/latest' title='Go to release in GitHub...'><img src='${RE_SHI}' alt='Release'></a> " )
			            <a href='https://moho.lostmarble.com/' title='Go to Moho® homepage...'><img src='${TA_SHI}' alt='Moho'></a> 
			        </td>
			    </tr>
			</table>
			EOF
			) # ⬆ HEADER FORMATTING BLOCK: Use a RAM string block (⚠ Keep spaces-as-tabs intact upon editing!)
			
			if [[ "$script_id" == "$BUILD_CORE" ]]; then # THE CORE INTERCEPTION: We dump the array in clean order
				MD_STARRED=""
				for i in "${!ST_ARR[@]}"; do
					MD_STARRED="${MD_STARRED}${ST_ARR[$i]}"$'\n' # The appended $'\n' is for extra line break
				done
			fi

			awk -v start="$H_START" -v end="$H_END" -v header="$HEADER_HTML" -v s_start="$MD_STARSTART" -v s_end="$MD_STAREND" -v s_content="$MD_STARRED" -v is_core="$([[ "$script_id" == "$BUILD_CORE" && -n "$MD_STARRED" ]] && echo "true" || echo "false")" \
			'
			$0 ~ start { print; print header; inside_h=1; next }
			$0 ~ end { inside_h=0 }
			is_core == "true" && $0 ~ s_start { print; print s_content; inside_s=1; next }
			is_core == "true" && $0 ~ s_end { inside_s=0 }
			!inside_h && !inside_s { print }
			' "$WRITEME_TMP" > "${WRITEME_TMP}.tmp" && mv "${WRITEME_TMP}.tmp" "$WRITEME_TMP" # ⬆ MULTI-INJECTION BLOCK: If it's the Core and there are cards, pass the Starred markers to AWK to clean and inject everything in the same disk read safely and treating variables as text literals

			if [[ "$script_id" == "$BUILD_CORE" && -n "$MD_STARRED" ]]; then
				echo "    ✴  Featured Cards injected & cleaned in Core's templates."
			fi
		fi

		# C. 📤 DERIVE ARTIFACTS FROM THE COOKED MASTER DISK FILE
		awk -v s1="$H_START" -v e1="$H_END" -v s2="$MD_STARSTART" -v e2="$MD_STAREND" '$0 !~ s1 && $0 !~ e1 && $0 !~ s2 && $0 !~ e2 { print }' "$WRITEME_TMP" > "$WRITE2WEBS" # Strip all markers from the master template to build the flat website asset

		cp -f "$WRITE2WEBS" "$WRITE2READ" # Derive GitHub README directly from the already cleaned website asset...
		perl -0777 -pi -e 's/\A---\r?\n.*?---\r?\n\s*//s' "$WRITE2READ" 2>/dev/null || true # ...by shaving off its YAML Front Matter

		rm -f "$WRITEME_TMP" 2>/dev/null || true # Clean up master working temporary file

		# D. 🚚 DISTRIBUTION GATEKEEPER (DOCSCOOK + Standard package deployment strategy)
		mkdir -p "$TARGET_DIR/docs"
		cp -f "$WRITE2READ" "$TARGET_DIR/docs/README.md" # Ensure a final tracked README in local package destination mainly for GitHub
		if [ -d "$DOCSDIR/$BUILD_WEBRSCS" ]; then
			rm -rf "$TARGET_DIR/docs/$BUILD_WEBRSCS" # Clean up the destination to avoid orphaned assets before cloning?
			mkdir -p "$TARGET_DIR/docs/$BUILD_WEBRSCS"
			cp -r "$DOCSDIR/$BUILD_WEBRSCS/"* "$TARGET_DIR/docs/$BUILD_WEBRSCS/" 2>/dev/null || true # Ensure a tracked assets folder as well for same reason
		fi

		if [[ "${BUILD_ASSIST[ENABLE]}" == "true" ]] && [[ -n "$BUILD_WEBPATH" && -d "$BUILD_WEBPATH/$script_id" ]]; then # Level 2: Static site deployment via ASSIST master switch
			WEB_DEST_DIR="$BUILD_WEBPATH/$script_id"
			WEB_TARGET_FILE="$WEB_DEST_DIR/${BUILD_WEBFILE}.md"
			
			if [[ "$script_id" == "$BUILD_CORE" && "${BUILD_ASSIST[DOCSCOOK]}" == "false" ]]; then # DOCSCOOK PROTECTION: If it's the Core but DOCSCOOK is false, skip the static website synchronization
				true # No hace nada con la web
			elif [ -f "$WEB_TARGET_FILE" ] && grep -q "Buildme:[[:space:]]*false" "$WEB_TARGET_FILE"; then
				echo "    ⚠️  Site Sync skipped: 'Buildme: false' detected for $script_id"
			else
				if [ "$HAS_FM" = false ] && [ -f "$WEB_TARGET_FILE" ] && head -n 1 "$WEB_TARGET_FILE" | grep -q '^---$'; then # If the web file exists and HAS_FM is false, rescue its production Front Matter safely using sed/cat
					RESCUED_FM=$(sed -n '1,/^---$/p' "$WEB_TARGET_FILE")
					printf "%s\n\n" "$RESCUED_FM" > "$WEB_TARGET_FILE"
					cat "$WRITE2WEBS" >> "$WEB_TARGET_FILE"
				else # Fresh deployment (Direct override)
					cp -f "$WRITE2WEBS" "$WEB_TARGET_FILE"
				fi
				if [ -d "$DOCSDIR/$BUILD_WEBRSCS" ]; then # Sync web assets folder
					mkdir -p "$WEB_DEST_DIR/$BUILD_WEBRSCS"
					cp -r "$DOCSDIR/$BUILD_WEBRSCS/"* "$WEB_DEST_DIR/$BUILD_WEBRSCS/" 2>/dev/null || true
				fi
				echo "    📑 Markdown updated and moved to destination via Auto-Assist."
			fi
		fi

		# E. 🧹 WORKSPACE WORK CLEANUP (Keep WRITE2READ only if ASSIST is false so you can check it)
		if [[ "${BUILD_ASSIST[ENABLE]}" == "true" ]]; then
			rm -f "$WRITE2READ" "$WRITE2WEBS" 2>/dev/null || true
		else
			rm -f "$WRITE2WEBS" 2>/dev/null || true
		fi
		echo -e "    ✅ Documentation pipeline finalized for: ${T_i}$script_id${T_N}"
	fi

	# --- ⭐ 2.6 STARRED/FEATURED CARD GENERATOR (Back to the main loop context)
	if [[ "$v_skip" == false ]] && [[ -n "$MD_STARDATA" && ",$MD_STARDATA," == *",$script_id,"* ]]; then
		ST_GIT="https://github.com/${BUILD_FORGE[USER]}/${script_id}"
		
		if [[ -n "$v_zip_url" ]]; then # Download shield: We use v_zip_url, which is already calculated in Customs (2.4c)
			ST_DLS_IMG="<img src='https://img.shields.io/github/downloads/${BUILD_FORGE[USER]}/${script_id}/total?logo=data:image/svg%2bxml;base64,${ICON_DL_B64}&color=blue&label=' alt='Download' title='Download: ${script_id}.zip' width='160'>"
			ST_LNK="$v_zip_url"
		else
			ST_DLS_IMG="<img src='https://img.shields.io/badge/Soon…-inactive.svg' alt='Download' title='Download: Unavailable' width='160'>"
			ST_LNK="${ST_GIT}"
		fi
		# Starred item table (⚠ Keep spaces-as-tabs intact upon editing!): Build the table directly inside a standard string variable
		ST_CARD=$(cat <<- EOF
		<table width='100%' border='3' class='card'><tr>
		    <td align='center' width='96'><a href='${ST_GIT}'>${PICTURE_TAG}</a></td>
		    <td width='724'><div><a href='${ST_GIT}'><strong>${v_name}</strong></a><br>${v_dsc:-$v_dsc_plain}</div></td>
		    <td align='center' width='192'><a href='${ST_LNK}'>${ST_DLS_IMG}</a></td>
		</tr></table>
		EOF
		)
		ST_INDEX=$(echo "$MD_STARDATA" | tr ',' '\n' | grep -n "^${script_id}$" | cut -d: -f1) # BUSCAMOS SU ORDEN EN EL YAML (Ej: si es el primero, devuelve 1; si es el segundo, 2) Convertimos la lista "ls_shapes,ls_dummy" en filas y buscamos la línea exacta
		if [[ -n "$ST_INDEX" ]]; then # Guardamos la tarjeta directamente en esa posición del array (ej: ST_ARR[1], ST_ARR[2])
			ST_ARR[$ST_INDEX]="$ST_CARD"
		fi
	fi

	# --- 🎁 2.7. SCRIPT ZIP GENERATION (Optional & Local)
	zipper "$script_id" "$TARGET_DIR" "$(expander "$BUILD_DISTDIR")" || ((++REPORT[ISS])) || true
	((++REPORT[TOT]))

	# --- 🚀 2.8. GIT SYNC & CATALOG DATA
	if [ -d "$TARGET_DIR/.git" ] || [[ "$script_id" == "$BUILD_CORE" ]]; then
		[[ -d "$TARGET_DIR/.git" ]] && cd "$TARGET_DIR" || true

		# 📶 A. REMOTE CHECK (Essential to know if the script is "catalogable")
		HAS_REMOTE=false
		if git remote 2>/dev/null | grep -q "origin"; then
			HAS_REMOTE=true
		elif [ "$BUILD_PUBLISH" = true ] && [ -d "$TARGET_DIR/.git" ]; then # Only try to add remote if we want to publish
			REMOTE_URL="${BUILD_FORGE[PREF]}:${BUILD_FORGE[USER]}/${script_id}.git"
			echo -e "    ⚠️  ${T_y}Warning:${T_N} No remote 'origin' detected..."
			read -n 1 -p "    🔗 Add '$REMOTE_URL' and push? (y/n): " answer < /dev/tty; echo ""
			if [[ "$answer" =~ ^[yY]$ ]]; then
				if git remote add origin "$REMOTE_URL"; then
					echo "    ✅ Remote added."; HAS_REMOTE=true
				else
					echo -e "    ❎ ${T_R}ERROR:${T_N} Could not add remote."; ((++REPORT[ISS]))
				fi
			fi
		fi

		# 🗳️ B. DATA COLLECTION FOR CATALOG & SYNC (As long as the pack has a remote or it's the Core!)
		if [ "$HAS_REMOTE" = true ] || [[ "$script_id" == "$BUILD_CORE" ]]; then
			# B1. COLLECTION (Whenever there is a remote, publishing or not)
			if [[ "$v_skip" == false ]]; then
				echo "$script_id|$v_name|$v_ver|$v_bld|$v_dsc|$v_tar|$v_zip_url|$v_stg|$PICTURE_TAG" >> "$MD_CATADATA" # Unless skipped, records are always written, whether it's DRY RUN or not
			fi

			# B2. SYNC LOGIC (Only if PUBLISH is true and there is remote)
			if [ "$BUILD_PUBLISH" = true ] && [ "$HAS_REMOTE" = true ]; then
				echo "    🌐 [Git] SYNCING: $script_id"
				git add .
				
				HAS_CHANGES=false; ! git diff --cached --quiet && HAS_CHANGES=true # B2a. Check if there are changes in the stage (index)
				IS_NEW=false; ! git rev-parse @{u} >/dev/null 2>&1 && IS_NEW=true # B2b. Check if the repo is new (it doesn't have an initial commit on the remote)
				if [ "$HAS_CHANGES" = true ] || [ "$IS_NEW" = true ]; then
					if [ "$IS_NEW" = true ] && [ "$HAS_CHANGES" = false ]; then # Decide the message: "Initial upload" if new and without stage changes, or "DNA-Sync" from the monorepo if there are changes
						MSG="Initial upload"
					else
						MSG="$MONO_MSG (@$MONO_HASH)"
					fi
					if [ "$HAS_CHANGES" = true ]; then # Commit ONLY if there is something to
						git commit -m "$MSG" >/dev/null 2>&1
						echo -e "    ⬆️  [Git] COMMIT: $MSG"
					fi
					if git push -u origin main >/dev/null 2>&1; then # Attempt the push (whether there is new commit or is a new empty repo)
						echo "    🚀 [Git] SUCCESS: Done!"
					else
						echo -e "    ❎ [Git] ${T_R}ERROR:${T_N} Push failed!"
						[ "$HAS_CHANGES" = true ] && git reset --soft HEAD~1 >/dev/null 2>&1 # Only reset if we end up creating a local commit
						((++REPORT[ISS])) 
					fi
				else
					echo "    🧼 [Git] CLEAN: Up to date."
				fi
			fi
			((++REPORT[PUB]))
		fi
		[[ -d "$TARGET_DIR/.git" ]] && cd - > /dev/null || true
	else
		if [ "$BUILD_PUBLISH" = true ]; then # Only log that it's local-only if the user intended to post
			echo "    ℹ️  $script_id is local-only (No .git folder)."
		fi
		((++REPORT[LOC]))
	fi
done

# 3. 🖇 PROCESS REMAINING SHARED ASSETS & DEPENDENCIES
if [[ "${BUILD_ASSIST[ENABLE]}" == "true" && "${BUILD_ASSIST[SYMLINKS]}" == "true" ]]; then
	if [[ -n "$MOHO_TARGET_DIR" && ${#BUILD_SYMLINKS[@]} -gt 0 ]]; then
		echo -e "🔗 Linking Shared Assets & Dependencies..."
		for shared_item in "${BUILD_SYMLINKS[@]}"; do
			[[ "$shared_item" != *"/"* ]] && continue # Skip pack identifiers to process only shared literal paths (items containing a slash)
			src_shared="$CORE_DEST/$shared_item"; dst_shared="$MOHO_TARGET_DIR/$shared_item"
			[[ ! -e "$src_shared" ]] && continue
			
			if [[ ! -e "$dst_shared" || -L "$dst_shared" ]]; then # SAFETY CHECK: Protect real shared files or directories
				rm -rf "$dst_shared"
				mkdir -p "$(dirname "$dst_shared")"
				ln -s "$(realpath --relative-to="$(dirname "$dst_shared")" "$src_shared")" "$dst_shared"
			else
				echo -e "    ⚠️  ${T_y}WARNING (Skipped symlink):${T_N} Real shared item exists at: ${T_d}Scripts/${dst_shared#$MOHO_TARGET_DIR/}${T_N}"
			fi
		done
	fi
fi

# 3. 📖 CATALOG GENERATION (RAM optimized)
echo "--- 📝 Updating Monorepo's Catalog..."

if [ -s "$MD_CATADATA" ]; then # Start reordering and processing collected data
	LINE=$(grep "^${BUILD_CORE}|" "$MD_CATADATA") || true # Group the Core first and...
	LINES=$(grep -v "^${BUILD_CORE}|" "$MD_CATADATA" | sort -t'|' -k2) || true # ...then the others ordered by name (column 2)

	# 🔼 TABLE HEADER (⚠ Keep spaces-as-tabs intact upon editing!): Start building the catalog directly inside a standard string variable
	MD_CATALOG=$(cat <<- EOF
	<table id='catalog' width='100%' border='0'>
	    <thead>
	        <tr>
	            <th align='center' width='96'>Icon</th><th align='center' width='120'>Name</th><th align='center' width='1920'>Description</th><th align='center' title='Direct Download Links'>📦</th>
	        </tr>
	    </thead>
	    <tbody>
	EOF
	)

	# ↔️ TABLE BODY GENERATION: Remote icons so they're always visible!
	while IFS="|" read -r id name ver bld dsc tar url stg pic; do # Process Substitution technique `< <(...)` keeps the loop running in the main process and MD_CATALOG survives!
		[[ -z "$id" ]] || [[ "$id" == " " ]] && continue # Extra security for empty lines...
		PACK_LNK="${URL_BASE}/${id}/"
		STAGE_LABEL=""; [[ "$stg" != "STABLE" ]] && STAGE_LABEL="<strong><sub><ins>$stg</ins></sub></strong>"

		# ✨ DISPLAY CUSTOMIZATION: Core vs. Others
		if [[ "$id" == "$BUILD_CORE" ]]; then
			DISPLAY_NAME="<a href='${PACK_LNK}'><strong><em>LS&nbsp;<sup>Core</sup></em></strong></a>"
			DISPLAY_DESC="<strong><em><sup>${dsc}</sup></em></strong><br><sub>𝓲 </sub><em><sub title='Build: $bld'>v$ver</sub> ${STAGE_LABEL}<sub> For Moho $tar</sub></em>"
		else
			DISPLAY_NAME="<a href='${PACK_LNK}' style='text-decoration: none'><strong><sup>$name</sup></strong></a>"
			DISPLAY_DESC="<sup>$dsc</sup><br><sub>𝓲 </sub><em><sub title='Build: $bld'>v$ver</sub> ${STAGE_LABEL}<sub> For Moho $tar</sub></em>"
		fi

		# 📝 ROW GENERATION (⚠ Keep spaces-as-tabs intact upon editing!): Append directly to the variable with a clean newline
		MD_CATALOG="${MD_CATALOG}"$'\n'"$(cat <<- EOF
	        <tr>
	            <td valign='middle' align='center'><a href='${PACK_LNK}'>$pic</a></td>
	            <td valign='middle' align='center'>${DISPLAY_NAME}</td>
	            <td valign='middle'>${DISPLAY_DESC}</td>
	            <td valign='middle' align='center'><a href='${url}' title='Download: ${id}.zip'><img src='${ICON_DL}' alt='Download'></a></td>
	        </tr>
		EOF
		)"
	done < <(echo "$LINE"; echo "$LINES"); MD_CATALOG="${MD_CATALOG}"$'\n'"    </tbody>"$'\n'"</table>" # Finalizing and closing the table

	# 🔽 LAYOUT FOOTER: Append to the RAM variable
	MD_CATALOG="${MD_CATALOG}"$'\n'"<p align='right'><sub>𝓲 <em>Generated by <strong>${INFO[NAME]}</strong><sup> v${INFO[VERSION]}</sup> @ <code>$(date +'%Y%m%d')</code></em></sub></p>"
fi

# 3c. Surgical Injection (With original, trusted, clean SED version)
if grep -q "$MD_CATASTART" "$MONO_READ" && grep -q "$MD_CATAEND" "$MONO_READ"; then # Both markers are present
	sed -i "\|$MD_CATASTART|,\|$MD_CATAEND|{ \|$MD_CATASTART|b; \|$MD_CATAEND|b; d; }" "$MONO_READ" # First, we delete ONLY what is strictly BETWEEN the markers
	echo "$MD_CATALOG" | sed -i "\|$MD_CATASTART|r /dev/stdin" "$MONO_READ" # CLEAN TRANSIT TRICK: Use, since sed requires a file, /dev/stdin to inject our variable directly through an echo without creating ANY temp file!
	echo "--- ✅ Catalog Injected Between Markers"
else
	echo -e "--- ⚠️  ${T_R} Warning:${T_N} Markers missing in README (appending at end to prevent data loss)"; ((++REPORT[ISS])) # Nothing gets deleted, just added at the end
  { echo -e "\n$MD_CATASTART"; echo "$MD_CATALOG"; echo -e "$MD_CATAEND\n"; } >> "$MONO_READ"
fi

# 3d. Final Cleanup and stuff...
rm -f "$MD_CATADATA"
if [ "$CANCELLED" = true ]; then echo -e "--- 🛑 ${T_g}ABORTED (Safely):${T_N} Built, but distribution aborted. Restarting... \n"; exec bash "$0"; fi; trap - SIGINT # Cancel checkpoint 5; Customized trap disabling

#SKIPPER # Comment/Uncomment along with `: << 'SKIPPER'` line above as needed!
: << 'COMMENT'
echo -e "--- 🚫 Multi-line comment example (This will never be run/printed!)"
COMMENT

# 4. 🔚 ENDING: RESTART/SHELL/[UPDATE]/EXIT?
echo -e "--- 🏁 ${T_B}DONE!${T_N} (Report: ⏱️  $(printf '%01d:%02d' $((SECONDS/60)) $((SECONDS%60))) | 📦 ${REPORT[TOT]} | 💻 ${REPORT[LOC]}$([ "$UPDATED_WORKSP" = true ] && echo " [$CURTIME]") | 🌐 ${REPORT[PUB]}$([ "$UPDATED_COMMIT" = true ] && echo " [$COMTIME]") | $([[ ${REPORT[ISS]} -gt 0 ]] && echo -ne "${T_R}❎${T_N}" || echo -ne "✅") ${REPORT[ISS]})"

FINAL_PROMPT="--- ？ ${T_S}R${T_N}estart? (${T_S}Y${T_N}es/${T_S}S${T_N}hell"
[[ "$BUILD_PUBLISH" == true ]] && FINAL_PROMPT="${FINAL_PROMPT}/${T_S}U${T_N}pdateMonorepo"
FINAL_PROMPT="${FINAL_PROMPT}/${T_S}Any${T_N}ToExit): "
echo -ne "$FINAL_PROMPT"; read -n 1 action; echo "" # Build the prompt string based on $BUILD_PUBLISH status

if [[ "$action" =~ ^[yYrR]$ ]]; then
	echo -e "--- 🔁 Restarting... \n"; sleep 0.5; exec bash "$0"
elif [[ "$action" =~ ^[sS]$ ]]; then
	echo -e "--- 💻 Entering Shell... ${T_d}(💡 Type 'exit' to return)${T_N}"
	bash --login -i; exec bash "$0"
elif [[ "$BUILD_PUBLISH" == true && "$action" =~ ^[uU]$ ]]; then # Logic for 'U' only executes if $BUILD_PUBLISH was true AND user pressed 'u'
	echo -e "--- 🌎 Updating Monorepo..."
	STASH_STAGE=$(git write-tree) # Snapshot of the stage
	git add . #git add "$MONO_READ" "$BUILD_DOCSDIR" (TBD: Stage all o just partially?)

	if ! git diff --cached --quiet; then # Show what will be uploaded (Summary mode)
		echo -e "--- 📦 ${T_y}Staged changes to be committed:${T_N}"
		git -c color.status=always status --short --branch | sed 's/^/    /' # The short status with branch and indentation
		git -c color.diff=always diff "$STASH_STAGE" --stat | tail -n 1 | sed 's/^/    🛈 /' # Summary of insertions/deletions by using diff --stat against the snapshot

		echo -e "--- 💬 ${T_S}Commit Message${T_N} ${T_d}(💡 'Ctrl+U'/EMPTY to cancel)${T_N}:"
		read -e -i "    Update: Monorepo and catalog (@$MONO_HASH)" user_msg
		user_msg_trimmed=$(echo "$user_msg" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') # Safety cleaning (Clear spaces/tabs at the beginning and end)
		
		if [[ -n "$user_msg_trimmed" ]]; then
			git commit -m "$user_msg_trimmed"
			git push -q origin main
			echo -e "--- ✅ Monorepo updated! Returning... \n"; sleep 1; exec bash "$0"
		else
			echo -e "--- 🛑 Cancelled (restoring previous stage). Returning... \n"
			git read-tree "$STASH_STAGE"
			sleep 1; exec bash "$0"
		fi
	else
		echo -e "--- 🧼 No changes to update in Monorepo. Returning... \n"; sleep 1; exec bash "$0"
	fi
else
	echo -e "--- ❎ Exiting... "; sleep 0.5; exit 0
fi