# 01 | use the official Ubuntu as the base image |
# ------------------------------------------------
	FROM ubuntu:latest


# 02 | expose needed ports |
# --------------------------
	EXPOSE 0


# 03-A | update & upgrade & install ubuntu mandatory tools & frappe dependances |
# -------------------------------------------------------------------------------
	RUN	apt-get update && apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive							                            \
			 apt-get install -y												                                                                      \
				sudo													                                                                                \
				nano													                                                                                \
				curl                                                                                                          \
				git													                                                                                  \
				redis-server												                                                                          \
				mariadb-client                                                                                                \
				libmysqlclient-dev                                                                                            \
				nginx                                                                                                         \
				cron                                                                                                          \
				python3                                                                                                       \
				python3-pip                                                                                                   \
				python3.10												                                                                            \
				python3.10-venv												                                                                        \
				fail2ban												                                                                              \
				wkhtmltopdf												                                                                            \
				libfontconfig												                                                                          \
				xvfb													                                                                                \
				supervisor											                                                                           &&	\
					echo "[program:nginx]" | tee -a /etc/supervisor/conf.d/supervisord.conf                                  &&	\
					echo "command=/usr/sbin/nginx -g 'daemon off;'" | tee -a /etc/supervisor/conf.d/supervisord.conf         &&	\
					echo "[program:redis]" | tee -a /etc/supervisor/conf.d/supervisord.conf								                   &&	\
					echo "command=/usr/bin/redis-server --bind 0.0.0.0" | tee -a /etc/supervisor/conf.d/supervisord.conf

# 03-B | install nodejs |
# -----------------------
	RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash                              &&	\
			/bin/bash -c "source ~/.nvm/nvm.sh && nvm install 16.15.1"											                             &&	\
			/bin/bash -c "source ~/.nvm/nvm.sh && nvm alias default 16.15.1"										                         &&	\
		curl -sL https://deb.nodesource.com/setup_16.x | bash -													                               &&	\
			apt-get install -y																	                                                            \
				nodejs
				

# 03-C | install yarn |
# ---------------------
	RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -												                     &&	\
		echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list								   &&	\
			apt-get update && apt-get install -y															                                              \
				yarn


# 004 | create new user:
# ----------------------
	ARG	GROUP_ID=1000 && USER_ID=1000 && USER_NAME=ubuntu

	RUN	groupadd -g $GROUP_ID $USER_NAME															                                               &&	\
		useradd --no-log-init -r -m -u $USER_ID -g $GROUP_ID -G sudo $USER_NAME											                   &&	\
		echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers												                               &&	\
		chown -R $USER_NAME:$USER_NAME /home/$USER_NAME														                                     &&	\
		chmod -R o+rx /home/$USER_NAME
		
		USER $USER_NAME
		WORKDIR /home/$USER_NAME


# 005 | :
# -------
	ENTRYPOINT ["sudo", "/usr/bin/supervisord", "-n"]


# 006 | install bench & frappe:
# -----------------------------

	ARG FRAPPE_FOLDER_NAME=frappe

	RUN /bin/bash -c "sudo pip3 install frappe-bench"
	RUN /bin/bash -c "bench init --frappe-branch version-14 $FRAPPE_FOLDER_NAME"
	WORKDIR /home/$USER_NAME/$FRAPPE_FOLDER_NAME
	RUN /bin/bash -c "bench set-config -g db_host mariadb"
