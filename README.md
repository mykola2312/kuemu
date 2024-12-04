# kuemu

Bash declarative QEMU tool

## Documentation

### Config
```KUEMU_DISK_PATH``` - set this to your appropriate location of virtual machine images.

```QEMU_BIOS_ROM```, ```QEMU_UEFI_ROM```, ```QEMU_UEFI_NVRAM``` - ensure they exist in your filesystem. If not, install required packages and firmware, for example for UEFI ROMs You need OVMF EDK2.

### Syntax

```name "name of virtual machine``` - set the name of VM. This also will be used in calculation of disk path

```arch "arch-suffix``` - will be translated into qemu-system-<arch>, like ```qemu-system-x86_64```

```machine "machine"``` - QEMU uses machine presets, that populates buses, devices and such. Recommended: q35

```cpu "cpu"``` - host, or custom cpu config

```smp num-cores``` - refers to amount of cores

```ram 1024m``` - same as -m parameter of QEMU. For example, 1G or 1024M are accepted.

```vga vga-type``` - VGA device. Recommended: qxl

```monitor``` - spawn QEMU monitor, useful for troubleshooting

```spice``` or ```spice <port>``` - spawn SPICE graphics server. Connect with ```spicy```

```no_acpi``` - disables ACPI. Needed for running old operating systems.

Path calculation:

"name" translates to ```$KUEMU_DISK_PATH/name.img```, "name" "fd" - ```$KUEMU_DISK_PATH/name.fd```

```uefi``` - loads UEFI ROMs, populates NVRAM variables into VM images path, like ```$KUEMU_DISK_PATH/name-nvram.fd```

```bios``` - loads BIOS ROM. Better don't use it, since QEMU has its own defaults.

```ide_disk "disk-name"```, ```sata_disk "name"```, ```virtio_disk "name"``` - creates IDE/SATA/Virtio disk drives, where ```name``` translates to ```$KUEMU_DISK_PATH/vm_name-name.img```. When ```name``` is empty string, it will translate just to virtual machine's name, like ```$KUEMU_DISK_PATH/vm_name.img```

```ide_cdrom "path"```, ```sata_cdrom "path"```, ```virtio_cdrom "path"``` - creates IDE/SATA/Virtio CDROMs, where "path" must be full path to file.

```network "device-model" "tap" "tap-name" "mac-address"``` - create network device. For model, you either specify ```e1000```, when guest doesn't have virtio drivers, or ```virtio-net``` for virtio network device. Example: ```network "virtio-net" "tap" "vnet0tap1" "52:54:00:12:34:56"```

```kuemu_start``` - finishes QEMU argument building and spawns virtual machine.

## Examples

### Full virtio guest
```
#!/usr/bin/env bash

source kuemu.sh

name      "freebsd-dev"
arch      "x86_64"
machine   "q35"
smp       4
ram       "4G"
vga       "qxl"
monitor
spice
uefi
virtio_disk ""
network   "virtio-net" "tap" "vnet0tap1" "d6:7d:05:31:93:61"

kuemu_start
```


### Windows 7
```
#!/usr/bin/env bash

source kuemu.sh

name      "win7"
arch      "x86_64"
machine   "q35"
smp       4
ram       "4G"
vga       "qxl"
monitor
spice
uefi
sata_disk ""
network   "e1000" "tap" "vnet0tap1" "d6:7d:05:31:93:61"

kuemu_start
```