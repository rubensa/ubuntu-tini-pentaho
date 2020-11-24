FROM rubensa/ubuntu-tini-x11
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Pentaho Version
ARG PENTAHO_VERSION=8.3
# PDI Version
ARG PDI_VERSION=8.3.0.0-371
# PDR Version
ARG PRD_VERSION=8.3.0.0-371

# MySQL Driver Version
ARG MYSQL_VERSION=5.1.49

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    #
    # Install needed libraries
    && apt-get update && apt-get -y install libwebkit2gtk-4.0 2>&1 \
    #
    # Download MySQL Driver
    && curl -o mysql-connector-java.tar.gz -sSL https://cdn.mysql.com/Downloads/Connector-J/mysql-connector-java-${MYSQL_VERSION}.tar.gz \
    && tar xvfz mysql-connector-java.tar.gz --directory /tmp \
    && rm mysql-connector-java.tar.gz \
    #
    # Install PDI
    && curl -o pdi-ce.zip -sSL https://netcologne.dl.sourceforge.net/project/pentaho/Pentaho%20${PENTAHO_VERSION}/client-tools/pdi-ce-${PDI_VERSION}.zip \
    && unzip pdi-ce.zip -d /opt \
    # Fix GTK 3 issues with SWT
    && sed -i 's/SWT_GTK3=0/SWT_GTK3=1/' /opt/data-integration/spoon.sh \
    && rm pdi-ce.zip \
    #
    # Add MySQL driver
    && cp /tmp/mysql-connector-java-${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}.jar /opt/data-integration/lib \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/data-integration \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/data-integration \
    #
    # Configure PDI for the non-root user
    && printf "\nexport PATH=/opt/data-integration:\$PATH\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Install PRD
    && curl -o prd-ce.zip -sSL https://netcologne.dl.sourceforge.net/project/pentaho/Pentaho%20${PENTAHO_VERSION}/client-tools/prd-ce-${PRD_VERSION}.zip \
    && unzip prd-ce.zip -d /opt \
    && rm prd-ce.zip \
    #
    # Add MySQL driver
    && cp /tmp/mysql-connector-java-${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}.jar /opt/report-designer/lib/jdbc \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/report-designer \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/report-designer \
    #
    # Configure PDR for the non-root user
    && printf "\nexport PATH=/opt/report-designer:\$PATH\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Delete temprary files
    && rm -rf /tmp/mysql-connector-java-${MYSQL_VERSION} \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${USER_NAME}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME /home/$USER_NAME

# Install Java 8 for the non-root user
RUN /bin/bash -i -c "export JAVA_VERSION=8.0; export JAVA_INSTALL_VERSION=\$(sdk list java | grep -o \"\${JAVA_VERSION}\\.[0-9\\.]*hs-adpt\" | head -1); yes | sdk install java \$JAVA_INSTALL_VERSION || true; ln -s /opt/sdkman/candidates/java/\$JAVA_INSTALL_VERSION /opt/sdkman/candidates/java/\$JAVA_VERSION;"
