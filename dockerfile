FROM registry.access.redhat.com/ubi9:latest                                                                                	 
                                                                                            	 
COPY healthcheck /healthcheck                                                              	 
COPY entrypoint  /entrypoint                                                               	 
                                                                                            	 
RUN  chmod 755 /healthcheck /entrypoint                                                                                            	 
CMD ["/entrypoint"]                                                                        