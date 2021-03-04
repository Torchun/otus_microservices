[docker]
%{ for i,name in dockerhost_names ~}
${dockerhost_names[i]} ansible_host=${dockerhost_addrs[i]}
%{ endfor ~}
