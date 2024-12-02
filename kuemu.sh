KUEMU_DISK_PATH="/drive/virtual-machines"

QEMU_BIOS_ROM="/usr/share/qemu/bios-microvm.bin"
QEMU_UEFI_ROM="/usr/share/OVMF/OVMF_CODE.fd"
QEMU_UEFI_NVRAM="/usr/share/OVMF/OVMF_VARS.fd"
QEMU_ACCEL="kvm"

QEMU_MODEL_IDE_BUS="piix3-ide"
QEMU_MODEL_AHCI_BUS="ahci"

vm_name=""
cmdline_file=$(mktemp)

model_ide_bus="$QEMU_MODEL_IDE_BUS"
model_ahci_bus="$QEMU_MODEL_AHCI_BUS"

function append() {
  printf "%s " "$1" >> "$cmdline_file"
}

function counter_create() {
  counter=$(mktemp)
  echo "$1" > "$counter"
  echo "$counter"
}

function counter_read() {
  cat "$1"
}

function counter_increment() { 
  echo $(( $(cat "$1") + 1 )) > "$1"
}

function counter_decrement() {
  echo $(( $(cat "$1") - 1 )) > "$1"
}

function counter_delete() {
  rm "$1"
}

function path_disk() {
  #
  # disk_name
  # disk_name, ext
  if [ ! -z "$2" ]; then
    echo "$KUEMU_DISK_PATH/$vm_name-$1.$2"
  elif [ ! -z "$1" ]; then
    echo "$KUEMU_DISK_PATH/$vm_name-$1.img"
  else
    echo "$KUEMU_DISK_PATH/$vm_name.img"
  fi
}

function name() {
  vm_name="$1"
}

function arch() {
  append "qemu-system-$1"
}

function machine() {
  append "-machine type=$1,accel=$QEMU_ACCEL"
}

function cpu() {
  if [ ! -z "$1" ]; then
    append "-cpu $1"
  else
    append "-cpu host"
  fi
}

function smp() {
  append "-smp $1"
}

function ram() {
  append "-m $1"
}

function vga() {
  append "-vga $1"
}

function monitor() {
  append "-monitor stdio"
}

function spice() {
  # port
  if [ ! -z "$1" ]; then
    append "-spice port=$1,disable-ticketing=on"
  else
    append "-spice port=5924,disable-ticketing=on"
  fi
}

function no_acpi() {
  append "-no-acpi"
}

function uefi() {
  append "-drive if=pflash,format=raw,file=$QEMU_UEFI_ROM"
  nvram=$(path_disk "nvram" "fd")
  if [ ! -f "$nvram" ]; then
    # create nvram
    cp "$QEMU_UEFI_NVRAM" "$nvram"
  fi
  append "-drive if=pflash,format=raw,file=$nvram"
}

function bios() {
  append "-bios $QEMU_BIOS_ROM"
}

function boot() {
  append "-boot $1"
}

bus_ide="ide"
bus_ide_counter=$(counter_create 0)

drive_counter=$(counter_create 0)

function _ide_disk() {
  # disk type, type, path
  unit=$(counter_read $bus_ide_counter)
  counter_increment $bus_ide_counter

  drive="drive-$(counter_read $drive_counter)"
  counter_increment $drive_counter

  append "-drive id=$drive,format=raw,media=$2,file=$3,if=none"
  append "-device $1,drive=$drive,bus=$bus_ide.$unit"
}

function ide_disk() {
  # name
  _ide_disk "ide-hd" "disk" $(path_disk "$1")
}

function ide_cdrom() {
  # path
  _ide_disk "ide-cd" "cdrom" "$1"
}

bus_ahci=""
bus_ahci_counter=$(counter_create 0)

function _sata_disk() {
  # disk type, media type, path
  if [ -z "$bus_ahci" ]; then
    append "-device $model_ahci_bus,id=ahci"
    bus_ahci="ahci"
  fi
  unit=$(counter_read $bus_ide_counter)
  counter_increment $bus_ahci_counter

  drive="drive-$(counter_read $drive_counter)"
  counter_increment $drive_counter

  append "-drive id=$drive,format=raw,media=$2,file=$3,if=none"
  append "-device $1,drive=$drive,bus=$bus_ahci.$unit"
}

function sata_disk() {
  # name
  _sata_disk "ide-hd" "disk" $(path_disk "$1")
}

function sata_cdrom() {
  # path
  _sata_disk "ide-cd" "cdrom" "$1"
}

function _virtio_disk() {
  # scsi type, media type, path
  drive="drive-$(counter_read $drive_counter)"
  counter_increment $drive_counter

  append "-drive id=$drive,format=raw,media=$2,file=$3,if=virtio"
}

function virtio_disk() {
  # name
  _virtio_disk "scsi-hd" "disk" $(path_disk "$1")
}

function virtio_cdrom() {
  # path
  _virtio_disk "scsi-cd" "cdrom" "$1"
}

nic_counter=$(counter_create 0)
function network() {
  # model, mode (tap or bridge), tap name / bridge
  nic="nic$(counter_read $nic_counter)"
  counter_increment $nic_counter

  append "-device $1,netdev=$nic"
  case "$2" in
    "tap")
      append "-netdev tap,id=$nic,ifname=$3,script=no,downscript=no"
      ;;
    *)
      echo "unknown network type $2"
      exit 1
      ;;
  esac
}

function kuemu_start() {
  append "-name $vm_name"
  # cleanup counters
  counter_delete $bus_ide_counter
  counter_delete $drive_counter
  counter_delete $bus_ahci_counter
  counter_delete $nic_counter
  # execute qemu command
  bash $cmdline_file
}

