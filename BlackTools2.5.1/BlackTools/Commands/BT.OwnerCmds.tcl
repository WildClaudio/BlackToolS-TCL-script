#########################################################################
##          BlackTools - The Ultimate Channel Control Script           ##
##                    One TCL. One smart Eggdrop                       ##
#########################################################################
#########################   OWNER CMDS TCL   ############################
#########################################################################
##						                       ##
##     BlackTools  : http://blacktools.tclscripts.net	               ##
##     Bugs report : http://www.tclscripts.net/	                       ##
##     Online Help : irc://irc.undernet.org/tcl-help 	               ##
##                   #TCL-HELP / UnderNet                              ##
##                   You can ask in english or romanian                ##
##					                               ##
#########################################################################


################################ Commands ###################################


################################## cp #######################################

proc cp:process {nick host hand chan chan1 type what from to} {
	global black
	set cmd_status [btcmd:status $chan $hand "cp" 0]
if {$cmd_status == "1"} { 
	return 
}
	set notvalid ""
if {![regexp {^[&#]} $from] || (![regexp {^[&#]} $to] && ![string equal -nocase $to "all"])} {
if {$type == "0"} {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr "cp"
}
if {$type == "1"} {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr_nick "cp"
}
if {$type == "2"} {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr_priv "cp"
}
	return
}

if {![validchan $from]} {
	lappend notvalid $from
}
if {![validchan $to]} {
	lappend notvalid $to
}
if {$notvalid != ""} {
	if {[llength $notvalid] > 1} {
	blacktools:tell $nick $host $hand $chan $chan1 cp.3 $notvalid
	} else {
	blacktools:tell $nick $host $hand $chan $chan1 cp.2 $notvalid
	}
	return
}
	switch $what {
	
	banlist {
	set counter 0
if {[llength [blacktools:banlist $from]] < 1} {
	blacktools:tell $nick $host $hand $chan $chan1 cp.1 $from
	return
}
	set file [open $black(bans_file) "a"]
	
	foreach b [blacktools:banlist $from] {
	set enc_chan [encoding convertto utf-8 $to]
	set read_type [lindex [split $b] 0]
	set read_host [lindex [split $b] 2]
	set read_hand [lindex [split $b] 3]
	set read_time1 [lindex [split $b] 4]
	set read_time2 [lindex [split $b] 5]
	set read_num1 [lindex [split $b] 6]
	set read_num2 [lindex [split $b] 7]
	set read_reason [lrange [split $b] 8 end]
	
	set return [blacktools:ban:exists $read_host $enc_chan]
if {$return == "0"} {
	set counter [expr $counter + 1]
	puts $file "$read_type [string tolower $enc_chan] [string tolower $read_host] $read_hand $read_time1 $read_time2 $read_num1 $read_num2 $read_reason"
	}
}
	close $file
	blacktools:tell $nick $host $hand $chan $chan1 cp.4 "$counter"
}

userlist {
	set time [unixtime]
	set counter 0
	set total_counter 0
foreach u [userlist] {
if {[matchattr $u $black(exceptflags) $from]} {
	set total_counter [expr $total_counter + 1]
	set cflags [chattr $u | $from]
if {![matchattr $cflags $to]} {
	set counter [expr $counter + 1]
	chattr $u $cflags $to
	setuser $u XTRA CHANMODIF($to) $time:cp_from_$from
			}
		}
	}
	blacktools:tell $nick $host $hand $chan $chan1 cp.5 "$counter $total_counter"
}

settings {
	set getflags [get:flags $from]
	set getstr [get:str $from]
	set counter 0
	set file [open $black(extra_file) a]
foreach flag $getflags {
	set return [blacktools:flag:exists $to $flag]
if {$return == "0"} {
	set counter [expr $counter + 1]
	puts $file "$to XTRA $flag"
	}
}
foreach str $getstr {
	set split_str [split $str ":"]
	set s [lindex $split_str 0]
	set why [lrange $split_str 1 end]
	set return [blacktools:flag:exists $to $s]
if {$return == "0"} {
	set counter [expr $counter + 1]
	puts $file "$to XTRA $s $why"
	}
}
	close $file
	blacktools:tell $nick $host $hand $chan $chan1 cp.6 "$counter"
}

	default {
if {$type == "0"} {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr "cp"	
				}
if {$type == "1"} {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr_nick "cp"
			}
		}
	}
}

############################## status #################################

proc status:process {nick host hand chan} {
	global black botnick server uptime {server-online} countusers version getowner
	set cmd_status [btcmd:status $chan $hand "status" 0]
if {$cmd_status == "1"} { 
	return 
}
	set getlang [string tolower [getuser $hand XTRA OUTPUT_LANG]]
if {$getlang == ""} { set getlang "[string tolower $black(default_lang)]" }
if {[matchattr $hand q]} { blacktools:tell $nick $host $hand $chan $chan1 gl.glsuspend none
	return
}
if {[matchattr $hand -|q $chan]} { blacktools:tell $nick $host $hand $chan $chan1 gl.suspend none
	return
}	
foreach c [channels] {
if {![setting:get $c invisible]} {
	lappend channels $c
	} else {
if {[matchattr $hand n]} {
	lappend channels \002$c\002
		}
	}
}
	set chan1 "$chan"
	blacktools:tell $nick $host $hand $chan $chan1 status.1 "$black(name) $black(vers) $version"
	blacktools:tell $nick $host $hand $chan $chan1 status.4 [join $channels]
	blacktools:tell $nick $host $hand $chan $chan1 status.5 "[countusers] [userlist n]"
}

############################## broadcast ##############################

proc broadcast:cmd:process {nick host hand chan chan1 text type} {
global botnick black
	set cmd_status [btcmd:status $chan $hand "broadcast" 0]
if {$cmd_status == "1"} { 
	return
}
if {[matchattr $hand q]} { blacktools:tell $nick $host $hand $chan $chan1 gl.glsuspend none
	return
}
if {[matchattr $hand -|q $chan]} { blacktools:tell $nick $host $hand $chan $chan1 gl.suspend none
	return
}
if {$text == ""} {
switch $type {
	0 {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr "broadcast"
	}
	1 {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr_nick "broadcast"
	}
	2 {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr_priv "broadcast"
		}
	}
	return 0
}

foreach c [channels] {
if {![setting:get $c silent]} {
	putserv "PRIVMSG $c :\[\002BROADCAST\002\] $text"
		}
	}
}

############################## msg ####################################

proc msg:process {nick host hand chan chan1 who msg type} {
	global black
	set cmd_status [btcmd:status $chan $hand "msg" 0]
if {$cmd_status == "1"} { 
	return
}
if {[matchattr $hand q]} { blacktools:tell $nick $host $hand $chan $chan1 gl.glsuspend none
	return
}
if {[matchattr $hand -|q $chan]} { blacktools:tell $nick $host $hand $chan $chan1 gl.suspend none
	return
}

if {$who == ""} {
switch $type {
	0 {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr "msg"
	}
	1 {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr_nick "msg"
	}
	2 {
	blacktools:tell $nick $host $hand $chan $chan1 gl.instr_priv "msg"
		}
	}
	return
}


if {[isbotnick $who]} { 
	return
}
	putserv "USERHOST :$who"
	bind RAW - 302 msg:online:check
	set ::msgnick $nick
	set ::hand $hand
	set ::host $host
	set ::chan $chan
	set ::chan1 $chan1
	set ::type $type
	set ::msg $msg
	set ::who $who
}

proc msg:online:check {from keyword arguments } {
	global black
	set msgnick $::msgnick
	set hand $::hand
	set host $::host
	set chan $::chan
	set chan1 $::chan1
	set who $::who
	set msg $::msg
	
	set hostname [lindex [split $arguments] 1]
if {[regexp {\+} $hostname]} {
	set split_host [split $hostname "+"]
} else {
	set split_host [split $hostname "-"]
}
	set mask [lindex $split_host 1]
	set getnick [string map {
			"=" ""
			":" ""
			} [lindex $split_host 0]]
if {$getnick != ""} {
if {[matchattr $hand -|A $chan] && [string equal -nocase $who $black(chanserv)]} {
	check:if:bind "msg:online:check" "302"
	return
}
if {$host != ""} {
if {[matchattr $hand -|AM $chan] && [onchan $who $chan]} {
	putserv "PRIVMSG $who :$msg"
	check:if:bind "msg:online:check" "302"
	return
	}
}
if {[matchattr $hand mno]} {
	putserv "PRIVMSG $who :$msg"
}
	} else {
	blacktools:tell $msgnick $host $hand $chan $chan1 gl.notonline "$who"
}
	check:if:bind "msg:online:check" "302"
}

############################### channels ########################

proc channels:process {nick host hand chan chan1} {
global botnick black
	set cmd_status [btcmd:status $chan $hand "channels" 0]
if {$cmd_status == "1"} { 
	return 
}
if {[matchattr $hand q]} { blacktools:tell $nick $host $hand $chan $chan1 gl.glsuspend none
	return
}
	set num [llength [channels]]
	set minusers "5"
	set getlang [string tolower [getuser $hand XTRA OUTPUT_LANG]]
if {$getlang == ""} { set getlang "[string tolower $black(default_lang)]" }

foreach c [channels] {
if {![setting:get $c invisible]} {
	set usersnumber [llength [chanlist $c]]
if {[channel get $c inactive]} {
if {[info exists black(abuse:$c)]} {
	lappend message_aschan "[join $c ", "]"
} else {
	lappend message_schan "[join $c ", "]"
}
} elseif {![onchan $botnick $c]} {
	lappend message_nchan "[join $c ", "]"	
} elseif {[onchan $botnick $c] && (![botisop $c]) && ($usersnumber >= $minusers)} {
	lappend message_ok "[join $c ", "]"
} elseif {[onchan $botnick $c] && ($usersnumber < $minusers)} {
	lappend message_nmin "[join $c ", "]"
}
if {[botisop $c] && ($usersnumber >= $minusers)} {
	lappend message_ok "[join @$c ", "]"
			}
		} else {
if {[matchattr $hand n]} {
	lappend message_inv "[join $c ", "]"
			}		
		}
	}

	blacktools:tell $nick $host $hand $chan $chan1 channels.1 $num
if {[info exists message_ok]} {
foreach word [wordwrap [join "\[$black(say.$getlang.channels.3)\]: $message_ok"] 350 ,] {
	blacktools:tell $nick $host $hand $chan $chan1 channels.2 $word
	}
}
if {[info exists message_nchan]} {
foreach word [wordwrap [join "\[$black(say.$getlang.channels.4)\]: $message_nchan"] 350 ,] {
	blacktools:tell $nick $host $hand $chan $chan1 channels.2 $word
	}
}
if {[info exists message_nmin]} {
foreach word [wordwrap [join "\[$black(say.$getlang.channels.7) < $minusers\]: $message_nmin"] 350 ,] {
	blacktools:tell $nick $host $hand $chan $chan1 channels.2 $word
	}
}
if {[info exists message_schan]} {
foreach word [wordwrap [join "\[$black(say.$getlang.channels.5)\]: $message_schan"] 350 ,] {
	blacktools:tell $nick $host $hand $chan $chan1 channels.2 $word
		}
	}
if {[info exists message_aschan]} {
foreach word [wordwrap [join "\[$black(say.$getlang.channels.6)\]: $message_aschan"] 350 ,] {
	blacktools:tell $nick $host $hand $chan $chan1 channels.2 $word
		}
	}
if {[info exists message_inv]} {
foreach word [wordwrap [join "\[$black(say.$getlang.channels.8)\]: $message_inv"] 350 ,] {
	blacktools:tell $nick $host $hand $chan $chan1 channels.2 $word
		}
	}
}

############################### nick ##################################

proc tempnick:process {thenick tonick host hand chan chan1 type} {
	global nick lastbind
	set cmd_status [btcmd:status $chan $hand "nick" 0]
if {$cmd_status == "1"} { 
	return 
}
if {$thenick == ""} {
switch $type {
	0 {
	blacktools:tell $tonick $host $hand $chan $chan1 gl.instr "nick"
	}
	1 {
	blacktools:tell $tonick $host $hand $chan $chan1 gl.instr_nick "nick"
	}
	2 {
	blacktools:tell $tonick $host $hand $chan $chan1 gl.instr_priv "nick"
		}
	}
	return
}
	set nick $thenick
	blacktools:tell $tonick $host $hand $chan $chan1 nick.4 $thenick		
}

proc nick:process {who newnick host hand chan} {
global black nick config
	set chan1 "$chan"
if {$newnick == ""} {
	blacktools:tell $who $host $hand $chan $chan1 nick.2 $newnick
	return
}
	blacktools:tell $who $host $hand $chan $chan1 nick.1 $newnick
	set ::lastnick [config:getinfo $config "set nick \"*\""]
	set nick [join $newnick]
	set error [config:save $config "set nick \"*\"" "set nick \"$newnick\""]
if {$error == "0"} {
	blacktools:tell $who $host $hand $chan $chan1 nick.3 ""
	}
	bind RAW - 432 check:validnickname
}

##############
#########################################################################
##   END                                                               ##
#########################################################################