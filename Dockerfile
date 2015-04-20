# BUILD-USING: docker build -t derbyjs/cypher
# RUN-USING: docker run --name cypher --rm derbyjs/cypher

# specify base docker image
FROM dockerfile/nodejs

# copy over dependencies
WORKDIR /var
RUN mkdir cypher

ADD package.json /var/cypher/
ADD server.coffee /var/cypher/

ADD apps /var/cypher/apps
ADD components /var/cypher/components
ADD server /var/cypher/server
ADD public /var/cypher/public
ADD config /var/cypher/config

# npm install all the things
WORKDIR /var/cypher
RUN npm install

RUN npm install -g coffee-script

# expose any ports we need
EXPOSE 8787
# the command that gets run inside the docker container
CMD ["/usr/local/bin/coffee", "/var/cypher/server.coffee"]
