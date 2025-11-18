
def prep-pass [] {
    $in 
    | lines
    | each {|line|
        if ($line | str starts-with '==') {
            parse "=={day}==" | $'===($in.day.0)'
        } else if ($line | str starts-with '|') {
            parse "|{entry_info}|" | $'|||($in.entry_info.0)'
        } else {
            $line
        }
    }
    | str join "\n"
}


def main [
    path: string
    --json
] {
    let a = open $path 
    | prep-pass
    | split row "==="

    let output = {
        date: ($a.0 | parse '{year}-{month}-{day}')
        days: ($a | skip 1 | each {
            let arr = split row "|||";
            {
                day: ($arr.0 | str trim)
                entries: ($arr | skip 1 | each { 
                    let array = split row "# ";
                    let stuff = $array.0 | parse "{entry} - {hours}"
                    {
                        entry: ($stuff.entry.0 | str trim)
                        hours: ($stuff.hours.0 | str trim)
                        notes: ($array | skip 1 | each {
                            let _notes = split row "- ";
                            {
                                title: ($_notes.0 | str trim)
                                notes: ($_notes | skip 1 | str trim)
                            }
                        })
                    }
                })
            }
        })
    } 
    if $json {
        $output | to json
    } else {
        $output
    }




}
