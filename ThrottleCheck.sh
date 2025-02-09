echo -e "\n\n\033[32mTIf you see an error, run the following commands to update AWK package.\nsudo apt-get update\nsudo apt-get upgrade -y\033[0m"
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

    # Fetching temperature limits
    temp_limits=$(nvidia-smi --query --display=TEMPERATURE | awk '
    /GPU T.Limit Temp/ {
        match($0, /: ([0-9-]+) C/, arr); 
        tlimit=arr[1]
    }
    /GPU Target Temperature/ {
        match($0, /: ([0-9-]+) C/, arr); 
        ttarget=arr[1]
    }
    END {print tlimit " " ttarget}')

    if [ -z "$temp_limits" ]; then
      echo "Error: Could not fetch temperature limits."
    else
      IFS=' ' read -r t_limit target_temp <<< "$temp_limits"
      echo -e "MAXTarget: $target_temp°C        GPU T.Limit Temp $t_limit°C        Current Clock $current_clock / $max_clock MHz";
    fi
  done;
  sleep 10;
done
