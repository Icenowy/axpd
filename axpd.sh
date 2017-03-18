#! /bin/bash
hex2dec(){
	echo 'ibase=16; obase=A; '"$1" | bc
}
checkbit(){
	[ $(( $1 & $(( 1 << $2 )) )) != 0 ]
}
readreg(){
	cat /sys/kernel/debug/regmap/sunxi-rsb-3a3/registers | grep ^$1: | cut -d ' ' -f 2 | tr a-z A-Z
}

modprobe test_power

while true
do
	echo off > /sys/module/test_power/parameters/ac_online
	echo LION > /sys/module/test_power/parameters/battery_technology
	source_status_reg=$(readreg 00)
	charger_status_reg=$(readreg 01)
	if checkbit 0x$source_status_reg 7
	then
		echo on > /sys/module/test_power/parameters/ac_online
		if checkbit 0x$charger_status_reg 6
		then
			echo charging > /sys/module/test_power/parameters/battery_status
		else
			echo not-charging > /sys/module/test_power/parameters/battery_status
		fi
	else
		echo off > /sys/module/test_power/parameters/ac_online
		echo discharging > /sys/module/test_power/parameters/battery_status
	fi
	hex=$(readreg b9)
	capacity=$(expr $(hex2dec $hex) - 128)
	if [ $capacity -ge 0 ]
	then
		echo $capacity | tee /sys/module/test_power/parameters/battery_capacity
	fi
	sleep 1
done

