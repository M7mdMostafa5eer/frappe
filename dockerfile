# 01 | use the official Ubuntu as the base image |
# ------------------------------------------------
	ARG PYTHON_VER=3.11.4 && IMG_TYPE=slim && DEBIAN_BASE=bookworm
	
	FROM python:${PYTHON_VER}-${IMG_TYPE}-${DEBIAN_BASE} AS base

# 02 | expose needed ports |
# --------------------------
	EXPOSE 0

# 03 | create variables |
# -----------------------
	ARG GROUP_ID=1000 && USER_ID=1000 && USER_NAME=frappe
	ARG NODE_VER=18.16.1
	ENV NVM_DIR=/home/${USER_NAME}/.nvm
	ENV PATH ${NVM_DIR}/versions/node/v${NODE_VER}/bin/:${PATH}
	ARG WKHTMLTOPDF_VER=0.12.6.1-3 && WKHTMLTOPDF_DISTRO=bookworm
	ARG FRAPPE_BRANCH=version-14 && FRAPPE_FOLDER_NAME=frappe-bench && FRAPPE_PATH=https://github.com/frappe/frappe

# 04 | create new user |
# ----------------------
	RUN	useradd -ms /bin/bash $USER_NAME															&&	\
		chown -R $USER_NAME:$USER_NAME /home/$USER_NAME

# 05 | update & install mandatory tools  |
# ----------------------------------------
	RUN	apt-get update && apt-get install --no-install-recommends -y			\
				curl																														\
				git																															\
				nano																														\
				nginx																														\
				gettext-base																										\
		# for weasyprint |
		# ----------------
				libharfbuzz0b																										\
				libpango-1.0-0																									\
				libpangoft2-1.0-0																								\
				libpangocairo-1.0-0																							\
		# for backups |
		# -------------
				restic																													\
		# database mariadb |
		# ------------------
				mariadb-client																									\
		# database postgres |
		# -------------------
				libpq-dev																												\
				postgresql-client																								\
		# install redis |
		#----------------
				redis-tools																											\
		# for healthcheck |
		# -----------------
				wait-for-it																											\
				jq																															\
		# nodejs & yarn |
		# ---------------
				&&	mkdir -p ${NVM_DIR}																						&&	\
				curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash								&&	\
				. ${NVM_DIR}/nvm.sh																							&&	\
				nvm install ${NODE_VER}																						&&	\
				nvm use v${NODE_VER}																						&&	\
				npm install -g yarn																							&&	\
				nvm alias default v${NODE_VER}																				&&	\
				rm -rf ${NVM_DIR}/.cache																					&&	\
				echo 'export NVM_DIR="/home/$USER_NAME/.nvm"' >>/home/${USER_NAME}/.bashrc									&&	\
				echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # This loads nvm' >>/home/${USER_NAME}/.bashrc	&&	\
				echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >>/home/${USER_NAME}/.bashrc	&&	\
		# wkhtmltopdf with patched qt |
		# -----------------------------
				if [ "$(uname -m)" = "aarch64" ]; 	then export ARCH=arm64; fi														&&	\
				if [ "$(uname -m)" = "x86_64" ]; 	then export ARCH=amd64; fi														&&	\
				Downloaded_File=wkhtmltox_${WKHTMLTOPDF_VER}.${WKHTMLTOPDF_DISTRO}_${ARCH}.deb										&&	\
				curl -sLO https://github.com/wkhtmltopdf/packaging/releases/download/$WKHTMLTOPDF_VER/$Downloaded_File				&&	\
				apt-get install -y ./$Downloaded_File																				&&	\
				rm $Downloaded_File																									&&	\
		# Clean up |
		# ----------
				rm -rf /var/lib/apt/lists/*																							&&	\
				rm -fr /etc/nginx/sites-enabled/default																				&&	\
		# Fixes for non-root nginx & logs to stdout |
		# -------------------------------------------
				sed -i '/user www-data/d' /etc/nginx/nginx.conf																		&&	\
				ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log							&&	\
				touch /run/nginx.pid																								&&	\
				chown -R ${USER_NAME}:${USER_NAME} /etc/nginx/conf.d																&&	\
				chown -R ${USER_NAME}:${USER_NAME} /etc/nginx/nginx.conf															&&	\
				chown -R ${USER_NAME}:${USER_NAME} /var/log/nginx																	&&	\
				chown -R ${USER_NAME}:${USER_NAME} /var/lib/nginx																	&&	\
				chown -R ${USER_NAME}:${USER_NAME} /run/nginx.pid

	RUN curl -LJO https://github.com/m7mdmostafa5eer/frappe/tree/main/nginx-conf/nginx-entrypoint.sh -o /usr/local/bin/nginx-entrypoint.sh
	RUN curl -LJO https://github.com/m7mdmostafa5eer/frappe/tree/main/nginx-conf/nginx-template.conf -o /templates/nginx/frappe.conf.template
			
	RUN pip3 install frappe-bench

	FROM base AS builder
	
	RUN	apt-get update && apt-get install --no-install-recommends -y									\
		# # For frappe framework |
		# ------------------------
				wget																					\
		# For psycopg2 |
		# --------------
				libpq-dev																				\
		# other |
		# -------
				libffi-dev																				\
				liblcms2-dev																			\
				libldap2-dev																			\
				libmariadb-dev																			\
				libsasl2-dev																			\
				libtiff5-dev																			\
				libwebp-dev																				\
				rlwrap																					\
				tk8.6-dev																				\
				cron																					\
		# for pandas |
		# ------------	
				gcc																						\
				build-essential																			\
				libbz2-dev																			&&	\
				rm -rf /var/lib/apt/lists/*

		USER ${USER_NAME}

		RUN bench init													\
			--frappe-branch ${FRAPPE_BRANCH}							\
			--frappe-path ${FRAPPE_PATH}								\
			--no-procfile												\
			--no-backups												\
			--skip-redis-config-generation								\
			--verbose													\
				/home/${USER_NAME}/${FRAPPE_FOLDER_NAME}

		WORKDIR /home/${USER_NAME}/${FRAPPE_FOLDER_NAME}
		
		VOLUME [	"/home/${USER_NAME}/${FRAPPE_FOLDER_NAME}/apps",	\
					"/home/${USER_NAME}/${FRAPPE_FOLDER_NAME}/sites",	\
					"/home/${USER_NAME}/${FRAPPE_FOLDER_NAME}/logs"			]

		CMD [		"/home/frappe/frappe-bench/env/bin/gunicorn",		\
					"--chdir=/home/frappe/frappe-bench/sites",			\
					"--bind=0.0.0.0:8000",								\
					"--threads=4",										\
					"--workers=2",										\
					"--worker-class=gthread",							\
					"--worker-tmp-dir=/dev/shm",						\
					"--timeout=120",									\
					"--preload",										\
					"frappe.app:application"								]
