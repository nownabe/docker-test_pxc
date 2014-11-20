name_base="pxc"
cluster_size=3
image="nownabe/pxc:5.5"

hosts=()
cluster_addr=""

for ((i=0; i<cluster_size; i++)); do
  name="${name_base}${i}"

  echo "==== Setup container ${name} ===="
  echo "* exec: docker run -d --name=\"${name}\" ${image}"
  docker run -d --name="${name}" ${image}

  echo "* exec: docker ps | grep "${name}" | awk '{print \$1}'"
  id=$(docker ps | grep "${name}" | awk '{print $1}')
  echo "ID of ${name}: ${id}"

  echo "* exec: docker inspect --format=\"{{ .NetworkSettings.IPAddress }}\" ${id}"
  ip=$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' ${id})
  echo "IP address of ${name}: ${ip}"

  echo "Waiting..."
  echo "* exec: sleep 10"
  sleep 10

  echo "Start MySQL service in ${name}"
  echo "* exec: ssh root@${ip} -i ./id_rsa -oStrictHostKeyChecking=no \"service mysql start --wsrep_cluster_address=gcomm://${cluster_addr}\""
  ssh root@${ip} -i ./id_rsa -oStrictHostKeyChecking=no "service mysql start --wsrep_cluster_address=gcomm://${cluster_addr}"

  cluster_addr="${ip},${cluster_addr}"
  hosts+=($ip)
  echo "==== Finish to setup container ${name} ===="
done

for h in "${hosts[@]}"; do
  echo "Rewrite my.cnf of ${h}"
  echo "* exec: ssh root@${h} -i ./id_rsa -oStrictHostKeyChecking=no \"sed -i 's|gcomm://|gcomm://${cluster_addr}|' /etc/my.cnf\""
  ssh root@${h} -i ./id_rsa -oStrictHostKeyChecking=no "sed -i 's|gcomm://|gcomm://${cluster_addr}|' /etc/my.cnf"
done

