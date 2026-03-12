source_="GJ625" # e.g. "CR_Draconis"
source=$(echo $source_ | sed 's/_/ /g')
path="/mnt/ucc1_recording1/data/observations/20260224T023000/20260224025951GJ625" # e.g. "/mnt/data/lofar/udp/2021-08-01"

zst_files=(${path}/*.zst)

start_time=$(echo "${zst_files[0]}" | awk -F '[/_T]' '{print $9}' | sed 's/..$//')
date=$(echo "${zst_files[0]}" | cut -d'/' -f8 | cut -d'.' -f3 | cut -dT -f1)
time=$(echo "${zst_files[0]}" | cut -d'/' -f8 | cut -dT -f2 | cut -d'.' -f1)
formatted_date=${date}T${time}
RA=$(python -c "from astropy.coordinates import SkyCoord; c = SkyCoord.from_name('$source'); print(c.ra.to_string(unit='hourangle', sep=':', precision=2))")
DEC=$(python -c "from astropy.coordinates import SkyCoord; c = SkyCoord.from_name('$source'); print(c.dec.to_string(unit='degree', sep=':', precision=2))")
RA_rad=$(python -c "from astropy.coordinates import SkyCoord; from astropy import units as u; c = SkyCoord.from_name('$source'); print(c.ra.to(u.radian).value)")
DEC_rad=$(python -c "from astropy.coordinates import SkyCoord; from astropy import units as u; c = SkyCoord.from_name('$source'); print(c.dec.to(u.radian).value)")

tstartmjd=$(python -c "from astropy.time import Time; print(Time('$formatted_date').mjd)" )


echo " =========== Processing filterbanks for $source =========== "
echo " Path: $path"
echo " Number of .zst files: $(ls -1a "${path}"/udp*.zst | wc -l)"
echo " Obs Date: $date"
echo " Obs Time: $time"
echo " RA:  $RA"
echo " DEC: $DEC"
echo " RA (rad): $RA_rad"
echo " DEC (rad): $DEC_rad"
echo " MJD Start: $tstartmjd"
echo " =========================================================== "

datetime="${obs_date} ${obs_time}"


# Extract the base port number from the first file
# Example: udp_16130.ucc1.2026-02-24T03:00:00.000.zst -> 16130
base_port=$(echo "${zst_files[0]}" | grep -oE 'udp_[0-9]+' | grep -oE '[0-9]+')

if [[ -z "$base_port" ]]; then
    echo "ERROR: Could not extract port number from ${zst_files[0]}"
    exit 1
fi

# Remove the last digit to get port prefix (16130 -> 1613)
port_prefix="${base_port%?}"

echo " Base port detected: $base_port"
echo " Port prefix for pattern: $port_prefix"

# Create the pattern string by replacing the full filename with the pattern
# This maintains the path and timestamp structure while using %d for port iteration
modified_string="${zst_files[0]//udp_${base_port}.ucc1/udp_${port_prefix}%d.ucc1}"

echo " Pattern string: $modified_string"



lofar_udp_extractor \
    -i "${modified_string}" \
    -u 4 \
    -p 154 \
    -a "-fch1 200 -fo -0.1953125 -source ${source_} -ra ${RA} -dec ${DEC}" \
    -d "${RA_rad},${DEC_rad},J2000" \
    -c "HBA,12:499" \
    -o "/mnt/ucc1_recording1/data/GJ625/${source_}_${formatted_date}_raw_S%d.fil" | tee -a "/mnt/ucc4_data2/data/David/GJ625_2026_02_24/logs/filgen_output_${source_}_${formatted_date}.log"

# --- Fil Generation ---
for i in {0..3}; do
    if [ ! -f "/mnt/ucc1_recording1/data/GJ625/${source_}_${formatted_date}_S${i}.fil" ]; then
        # echo "Running digifil for ${i + 1} out of 4 files"
        digifil -b-32 -t 128 -c -I 0 "/mnt/ucc1_recording1/data/GJ625/${source_}_${formatted_date}_raw_S${i}.fil" \
        -o "/mnt/ucc1_recording1/data/GJ625/${source_}_${formatted_date}_S${i}.fil"
        chmod 777 "/mnt/ucc1_recording1/data/GJ625/${source_}_${formatted_date}_S${i}.fil"
    else
        echo "File already exists: /mnt/ucc1_recording1/data/GJ625/${source_}_${formatted_date}_S${i}.fil skipping digifil"
    fi
done

# --- Clean Up ---
rm -f /mnt/ucc1_recording1/data/GJ625/${source}_${formatted_date}_raw_S*.fil