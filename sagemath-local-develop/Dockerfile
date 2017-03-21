FROM sagemath/sagemath-base
USER root
# Allow 'sage' user to use sudo without a password
RUN echo "sage    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
WORKDIR /src/sage
RUN chown -R sage:sage /src/sage
USER sage
CMD [ "./sage", "-sh" ]
