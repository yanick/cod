function cod

    set subcommand $argv[1]
    set -e argv[1]

    switch $subcommand
        case cd
            _cod.cd $argv
        case enter
            if test ( count $argv ) -gt 0
                echo $argv >> ( _cod.dir_for )/enter.fish
                return
            else
                eval $EDITOR ( _cod.dir_for )/enter.fish
            end
        case leave
            if test ( count $argv ) -gt 0
                echo $argv >> ( _cod.dir_for )/leave.fish
                return
            else
                eval $EDITOR ( _cod.dir_for )/leave.fish
            end
        case show
            set dir ( _cod.dir_for )
            echo "dir: $dir"
            for f in enter leave
                set ff ( _cod.dir_for )/$f.fish
                if test -f $ff 
                    echo $ff
                    cat $ff
                else
                    echo no $f file
                end
            end
    end

end

function _cod.cd 

    set current (pwd)

    # check if we lef any of the dirs we were in
    for i in ( seq 1 ( count $COD_DIRS ) | tac );
        set dir $COD_DIRS[$i]
        switch $current
            case $dir'*'
                # do nothing
            case '*'
                _cod.unstash $dir
                _cod.leave $dir
                set -e COD_DIRS[$i]
        end
    end;

    # have we entered one?
    eval set segments ( echo $current | sed 's/\// /g' )
    set current ""

    for segment in $segments
        set current $current/$segment

        if not contains $current $COD_DIRS 
            _cod.dir_func $current enter
            set -g COD_DIRS $COD_DIRS $current
        end

    end

end

function _cod.dir_func 
    if test (count $argv ) -lt 1
        set argv (pwd)
    end

    if set -q COD_DEBUG
        echo "cod $argv[2] - $argv[1]"
    end

    set file ( _cod.dir_for $argv[1] )/$argv[2].fish
    if test -f $file
        source $file
        return 0
    end

    return 1
end

function _cod.enter
    _cod.dir_func $argv[1] enter
end

function _cod.leave
    _cod.dir_func $argv[1] leave
end

function _cod.dir_for 
    if test (count $argv ) -lt 1
        set argv (pwd)
    end
    set dir ~/.cod/dirs$argv[1]
    mkdir -p $dir
    echo $dir
end

function _cod.stash 
    echo set -g $argv[1] ( eval echo '$'$argv[1] ) >> ( _cod.dir_for )/stash.fish
    set c $argv[1]
    set -e argv[1]

    set -g $c $argv
end

function _cod.stash_function
    set new_name _cod.$argv[1]( _cod.dir_to_name )
    functions -c $argv[1] $new_name
    echo functions -e $argv[1] >> ( _cod.dir_for )/stash.fish
    echo functions -c $new_name $argv[1] >> ( _cod.dir_for )/stash.fish
    echo functions -e $new_name >> ( _cod.dir_for )/stash.fish
end

function _cod.unstash
    if test (count $argv ) -lt 1
        set argv (pwd)
    end

    set file ( _cod.dir_for $argv[1] )/stash.fish

    if test -f $file
        source $file
        rm -f $file
    end
end

function _cod.dir_to_name
    if test ( count $argv ) -lt 1
        set argv[1] (pwd)
    end

    echo $argv[1]  | sed 's/\//_/g'
end

