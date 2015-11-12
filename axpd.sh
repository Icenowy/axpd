#!/bin/bash
checkbit(){
	(( $1 & (1 << $2) ))
}
rmmod -f battery
modprobe i2c-dev
modprobe test_power
case "$(find /sys -path '*axp288_charger*')" in
	(*i2c-12*)	export ADDR=12;; 
	(*i2c-4*)	export ADDR=4;;
	(*)		echo "WTF?"; exit 1;;
esac
while true
do
	rmmod battery 2>/dev/null
	echo off > /sys/module/test_power/parameters/ac_online
	echo LION > /sys/module/test_power/parameters/battery_technology
	source_status_reg=$(i2cget -f -y $ADDR 0x34 0x00)
	charger_status_reg=$(i2cget -f -y $ADDR 0x34 0x01)
	if checkbit $source_status_reg 4
	then
		echo on > /sys/module/test_power/parameters/usb_online
		if checkbit $charger_status_reg 6
		then
			echo charging > /sys/module/test_power/parameters/battery_status
		else
			echo not-charging > /sys/module/test_power/parameters/battery_status
		fi
	else
		echo off > /sys/module/test_power/parameters/usb_online
		echo discharging > /sys/module/test_power/parameters/battery_status
	fi
	((capacity = $(i2cget -f -y $ADDR 0x34 0xb9) - 128))
	if ((capacity > 0))
	then
		echo $capacity | tee /sys/module/test_power/parameters/battery_capacity
	fi
	sleep 10
done
