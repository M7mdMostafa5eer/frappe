# 01 | use the official Ubuntu as the base image |
# ------------------------------------------------
	FROM ubuntu:latest

# 02 | expose needed ports |
# --------------------------
	EXPOSE 0

# 03 | create variables |
# -----------------------
	ARG	GROUP_ID=1000 && USER_ID=1000 && USER_NAME=ubuntu
	ARG NODE_VER=18.16.1
	ENV	NVM_DIR=/home/${USER_NAME}/.nvm
	ENV PATH ${NVM_DIR}/versions/node/v${NODE_VER}/bin/:${PATH}
	ARG FRAPPE_BRANCH=version-14 && FRAPPE_FOLDER_NAME=frappe-bench && FRAPPE_PATH=https://github.com/frappe/frappe

# 03 | update & install mandatory tools  |
# ----------------------------------------
	RUN	apt-get update && apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive		\
			 apt-get install -y							\
				sudo								\
				curl								\
				git								\
				nano								\
				nginx								\
				gettext-base							\
		# for weasyprint |
		# ----------------
				libharfbuzz0b							\
				libpango-1.0-0							\
				libpangoft2-1.0-0						\
				libpangocairo-1.0-0						\
		# for backups |
		# -------------
				restic								\
		# database mariadb |
		# ------------------
				mariadb-client							\
		# database postgres |
		# -------------------
				libpq-dev							\
				postgresql-client						\
		# install redis |
		#----------------
				redis-server							\
		# for healthcheck |
		# -----------------
				wait-for-it							\
				jq								\
		# # For frappe framework |
		# ------------------------
				wget								\
		# For psycopg2 |
		# --------------
				libpq-dev							\
		# other |
		# -------
				libffi-dev							\
				liblcms2-dev							\
				libldap2-dev							\
				libmariadb-dev							\
				libsasl2-dev							\
				libtiff5-dev							\
				libwebp-dev							\
				rlwrap								\
				tk8.6-dev							\
				cron								\
				fail2ban							\
		# for pandas |
		# ------------	
				gcc								\
				build-essential							\
				libbz2-dev							\
		# install wkhtmltopdf |
		# ---------------------
				xvfb								\
				wkhtmltopdf							\
		# install python |
		# ----------------
				python3								\
				python3-pip							\
				python3.10							\
				python3.10-venv							\
		# nodejs & yarn |
		# ---------------
				&& mkdir -p ${NVM_DIR}												&&	\
				curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash					&&	\
				. ${NVM_DIR}/nvm.sh												&&	\
				nvm install ${NODE_VER}												&&	\
				nvm use v${NODE_VER}												&&	\
				npm install -g yarn												&&	\
				nvm alias default v${NODE_VER}											&&	\
				rm -rf ${NVM_DIR}/.cache											&&	\
				echo 'export NVM_DIR="/home/$USER_NAME/.nvm"' >>/home/${USER_NAME}/.bashrc					&&	\
				echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # This loads nvm' >>/home/${USER_NAME}/.bashrc	&&	\
				echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >>/home ${USER_NAME}/.bashrc

# 05 | install supervisor |
# -------------------------
	RUN	apt-get update && apt-get upgrade -y && apt-get install -y 									\
			supervisor													&&	\
				echo "[program:nginx]" | tee -a /etc/supervisor/conf.d/supervisord.conf					&&	\
				echo "command=/usr/sbin/nginx -g 'daemon off;'" | tee -a /etc/supervisor/conf.d/supervisord.conf	&&	\
				echo "[program:redis]" | tee -a /etc/supervisor/conf.d/supervisord.conf					&&	\
				echo "command=/usr/bin/redis-server --bind 0.0.0.0" | tee -a /etc/supervisor/conf.d/supervisord.conf

# 06 | Clean up |
# ---------------
	RUN	rm -rf /var/lib/apt/lists/*

# 07 | create new user |
# ----------------------
	RUN	groupadd -g ${GROUP_ID} ${USER_NAME}											&&	\
		useradd --no-log-init -r -m -u ${USER_ID} -g ${GROUP_ID} -G sudo ${USER_NAME}						&&	\
		echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers								&&	\
		chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}									&&	\
		chmod -R o+rx /home/${USER_NAME

# 08 | install frappe-bench |
# ---------------------------
	RUN pip3 install frappe-bench

	USER ${USER_NAME}

	RUN bench init																\
		--frappe-branch ${FRAPPE_BRANCH}												\
		--frappe-path ${FRAPPE_PATH}													\
		--no-procfile															\
		--no-backups															\
		--skip-redis-config-generation													\
		--verbose															\
			/home/${USER_NAME}/${FRAPPE_FOLDER_NAME}

	WORKDIR /home/${USER_NAME}/$FRAPPE_FOLDER_NAME

# 09 | setting entrypoint |
# -------------------------
	ENTRYPOINT ["sudo", "/usr/bin/supervisord", "-n"]
