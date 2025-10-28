FROM node:16-alpine

ARG USER_ID
ARG GROUP_ID

USER root

# create and chown needed dirs
RUN mkdir /.cache && chown $USER_ID:$GROUP_ID /.cache
RUN mkdir /.yarn && chown $USER_ID:$GROUP_ID /.yarn
RUN touch /.yarnrc && chown $USER_ID:$GROUP_ID /.yarnrc

# has to be installed globally
RUN yarn global add yalc

# use env user
USER $USER_ID:$GROUP_ID
