#!/bin/bash
# Usage example:
# RunFromGit "path/to/script.sh" "output.sh" "automation_name"

RunFromGit() {
    script=$1   # Path of file in GitHub repo
    outfile=$2  # File to execute (probably same as above sans dirs)
    automation_name=$3      # Used for temp dir names

    # Preconfigured variables
    ninja_dir='/tmp/NinjaRMMAgent'

    # Set up temp dirs
    mkdir -p "$ninja_dir/$automation_name"
    cd "$ninja_dir/$automation_name" || exit

    # Get the personal access token from S3
    echo 'Getting personal access token from S3...'
    pat_url='https://tangelo-ninja-repo.s3.ap-southeast-2.amazonaws.com/ninja_rmm_github.pat'
    pat=$(curl -s "$pat_url")
    if [[ $pat == github_pat* ]]; then
        echo 'Got personal access token'
    else
        echo 'Did not get personal access token'
    fi

    # Request the file from the GitHub repo
    echo 'Getting script from GitHub...'
    urlencoded_path=$(printf "%s" "$script" | jq -s -R -r @uri)
    echo $urlencoded_path
    curl -s -H "Authorization: Bearer $pat" -H "Accept: application/vnd.github.v3.raw" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/tangelo-services-org/ninja-rmm/contents/$urlencoded_path" \
        -o "$outfile"
    if [ -e "$outfile" ]; then
        echo "$outfile downloaded successfully"
    else
        echo "$outfile not downloaded"
    fi

    # Run the script
    echo "Running $outfile ..."
    chmod +x "$outfile"
    bash "./$outfile" 2>&1 
    echo "$outfile done, cleaning up..."

    Clean up
    cd "$ninja_dir" || exit
    rm -rf "$ninja_dir/$automation_name"
    if [ -e "$ninja_dir/$automation_name" ]; then
        echo "Failed to clean up $ninja_dir/$automation_name"
    else
        echo "Cleaned up $ninja_dir/$automation_name"
    fi
}


