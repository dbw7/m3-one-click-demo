# m3-one-click-demo

To run the main version run this command (DO NOT RUN THIS RIGHT NOW):<br>
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/main/script.sh)"
```

To run a version made to debug the helm charts without Sylva being deployed, run the following command (DO NOT RUN THIS RIGHT NOW):<br>
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/debug-non-sylva/script-debug1.sh)"
```

Need to be root user on a c2-medium-x86-01, c3-medium-x86-01 or s3.xlarge.x86 Ubuntu 22.04 LTS Equinix server (only configs I've tested this on so far)

If you don't know what this is, do not run this.


# This next section is for my personal convenience<br>

```
echo 'alias nw="sudo virsh destroy metal3-core; sudo virsh undefine metal3-core"' >> ~/.bashrc
echo 'alias infra="sudo virsh destroy metal3-network-infra; sudo virsh undefine metal3-network-infra"' >> ~/.bashrc
echo 'alias onehost="sudo ssh-keygen -R 192.168.125.100 -f /root/.ssh/known_hosts"' >> ~/.bashrc
echo 'alias twohost="sudo ssh-keygen -R 192.168.125.99 -f /root/.ssh/known_hosts"' >> ~/.bashrc
source ~/.bashrc
```
