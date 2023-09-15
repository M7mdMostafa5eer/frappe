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

 
# 05 | update & install mandatory tools  |
# ----------------------------------------
	RUN	apt-get update && apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive      \
			 apt-get install -y																			                    \
				sudo                                                                      \
				curl                                                                      \
				git														                            								\
				nano																					                            \
				nginx																				                            	\
				gettext-base																                        			\
		# for weasyprint |
		# ----------------
				libharfbuzz0b																			                        \
				libpango-1.0-0																		                      	\
				libpangoft2-1.0-0																	                      	\
				libpangocairo-1.0-0																                    		\
		# for backups |
		# -------------
				restic																				                          	\
		# database mariadb |
		# ------------------
				mariadb-client																			                      \
		# database postgres |
		# -------------------
				libpq-dev																				                          \
				postgresql-client																		                      \
		# install redis |
		#----------------
				redis-tools																				                        \
		# for healthcheck |
		# -----------------
				wait-for-it																			                        	\
				jq																						                            \
		# # For frappe framework |
		# ------------------------
				wget																					                            \
		# For psycopg2 |
		# --------------
				libpq-dev																				                          \
		# other |
		# -------
				libffi-dev																				                        \
				liblcms2-dev																			                        \
				libldap2-dev																			                        \
				libmariadb-dev																			                      \
				libsasl2-dev																			                        \
				libtiff5-dev																			                        \
				libwebp-dev																				                        \
				rlwrap																					                          \
				tk8.6-dev																				                          \
				cron																					                            \
				fail2ban																				                          \
		# for pandas |
		# ------------	
				gcc																						                            \
				build-essential																			                      \
				libbz2-dev																				                        \
		# install wkhtmltopdf |
		# ---------------------
				xvfb																					                            \
				wkhtmltopdf																				                        \
		# install python |
		# ----------------
				python3																					                          \
				python3-pip																				                        \
				python3.10																				                        \
				python3.10-venv																								        &&	\
		# nodejs & yarn |
		# ---------------
