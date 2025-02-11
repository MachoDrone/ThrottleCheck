#!/bin/bash

while true; do
  echo -e "\n$(date '+%Y-%m-%d %H:%M:%S')"
  nvidia-smi --query-gpu=index,gpu_name,fan.speed,pstate,clocks_throttle_reasons.hw_thermal_slowdown,clocks_throttle_reasons.sw_thermal_slowdown,memory.used,memory.total,utilization.gpu,temperature.gpu,power.draw,power.limit,clocks.current.sm,clocks.max.sm --format=csv,noheader,nounits | while IFS=',' read -r id name fan_speed pstate hw_throttle sw_throttle mem_used mem_total gpu_util temp power_draw power_limit current_clock max_clock; do
    mem_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used/$mem_total)*100}");
    power_draw_rounded=$(awk "BEGIN {printf \"%d\", $power_draw}");
    power_limit_rounded=$(awk "BEGIN {printf \"%d\", $power_limit}");
    if [[ "$hw_throttle" != " Not Active" ]]; then
      hw_throttle="\033[1;101m$hw_throttle \033[0m";
    else
      hw_throttle="\033[1;90m$hw_throttle \033[0m";
    fi;
    if [[ "$sw_throttle" != " Not Active" ]]; then
      sw_throttle="\033[1;95m$sw_throttle\033[0m";
    else
      sw_throttle="\033[1;90m$sw_throttle\033[0m";
    fi;
    cpu_mem_info=$(top -bn1 | grep "Cpu(s)\|Mem" | awk '/Cpu\(s\)/ {cpu_usage = int($2 + $4)} /MiB Mem/ {mem_total = int($4); mem_used = int($8)} END {printf "CPU_util: %d%%   RAM: %d / %dMiB", cpu_usage, mem_used, mem_total}');
    echo -e "id:$id   $name   vRAM: $mem_used / $mem_total ($mem_percent%)   GPU_util: $gpu_util%   Power: $power_draw_rounded / $power_limit_rounded W   perf_state: $pstate";
    echo -e "GPUtemp:  $temp°C   Fan: $fan_speed%   HW-throttle: $hw_throttle   SW-throttle: $sw_throttle* -- $cpu_mem_info";

    # Fetching temperature limits with compatibility for both mawk and gawk
    temp_limits=$(nvidia-smi --query --display=TEMPERATURE | awk '
    /GPU T.Limit Temp/ {
        split($0, arr, ": "); 
        split(arr[2], temp, " "); 
        tlimit=temp[1]
    }
    /GPU Target Temperature/ {
        split($0, arr, ": "); 
        split(arr[2], temp, " "); 
        ttarget=temp[1]
    }
    END {print tlimit " " ttarget}')
    if [[ -n "$temp_limits" ]]; then
      IFS=' ' read -r t_limit target_temp <<< "$temp_limits"
      echo -e "MAXTarget: $target_temp°C        GPU T.Limit Temp $t_limit°C        Current Clock $current_clock / $max_clock MHz";
    else
      echo -e "\033[31mError: Could not fetch some additional temperature limits. Please inform MachoDrone.\033[0m"
    fi
  done;
  sleep 10;
done
