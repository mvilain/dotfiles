[ -n "$PS1" ] && source ~/.bash_profile
for i in /usr/local/bin ; do
  if [ '$(echo $PATH | grep "${i}")X' == "X" ]; then export PATH="${i}:${PATH}"; fi
done
