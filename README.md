cypher
=============

real-time code hip-hop

```bash
git clone https://github.com/enjalot/cypher.git
cd cypher
npm install

coffee server.coffee
```

go to `localhost:8787` and create a room.  
Creating a room will also create a default cypher. Set your room up with content and data.

Until we have a good live demo, try creating a throw-away github account and logging in
to see another user's cursor in the code editor (when looking at the same code)


# TODOs

## Styling
  * non-ugly colors
  * sensible layouts

## Access control -
  * non-loggedin users shouldn't be able to write to any collections
  * loggedin users should only be able to write to rooms and cyphers they own
