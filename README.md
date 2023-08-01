# m3-one-click-demo
## 1, 2, and 3 all deploy the metal3-demo with different configurations, only run one of them, not all three
1. Main version without Sylva(This should be working):<br>
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/main-without-sylva/script-main.sh)"
```

2. Main version with Sylva (This should be working):<br>
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/main-with-sylva/script-main.sh)"
```

3. To run a version made to debug the helm charts without Sylva being deployed, run the following command:<br>
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/debug-non-sylva/script-debug1.sh)"
```

4. Main version connected to main repo (IN TESTING, DO NOT RUN):<br>
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/suse-edge-main/script-main.sh)"
```

VBMC stuff (This assumes that you have a full metal3 demo environment running exactly how the scripts set it up)
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/vbmc/vm.sh)"
```

VBMC No Image (This assumes that you have a full metal3 demo environment running exactly how the scripts set it up)
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/vbmc/vm_noimg.sh)"
```

Need to be root user on a m3-small-x86-01, c2-medium-x86-01, c3-medium-x86-01 or s3.xlarge.x86 Ubuntu 22.04 LTS Equinix server (only configs I've tested this on so far)

If you don't know what this is, do not run this.


# This next section is for my personal convenience<br>

```
echo 'alias nw="sudo virsh destroy metal3-core; sudo virsh undefine metal3-core"' >> ~/.bashrc
echo 'alias infra="sudo virsh destroy metal3-network-infra; sudo virsh undefine metal3-network-infra"' >> ~/.bashrc
echo 'alias onehost="sudo ssh-keygen -R 192.168.125.100 -f /root/.ssh/known_hosts"' >> ~/.bashrc
echo 'alias twohost="sudo ssh-keygen -R 192.168.125.99 -f /root/.ssh/known_hosts"' >> ~/.bashrc
source ~/.bashrc
```
