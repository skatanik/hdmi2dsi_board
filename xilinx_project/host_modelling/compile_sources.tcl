package require fileutil

set filenames [::fileutil::findByPattern ./../../rtl/ -glob {compile_module.tcl}]
foreach filename $filenames {
    if {[file isfile $filename]} {
        #set dirs_var([file dirname $filename])
        set file_path [file dirname $filename]
        do $filename
    }
}

vlog -sv -incr -work work $defines $include_dir ./../../rtl/top_level.v

#vlog -sv -incr -work work $defines $include_dir {*}dirs_var

