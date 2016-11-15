# OGPToolbox-UI

Web user interface for OGP toolbox

## Install dependencies

    npm install

This will install npm dependencies in `node_modules` and Elm dependencies in `elm-stuff`.

## Development

Start the hot-reloading webpack dev server:

    npm start

Navigate to <http://localhost:3011>.

Any changes you make to your files (.elm, .js, .css, etc.) will trigger
a hot reload.

## Production

When you're ready to deploy:

    npm run build

This will create a `dist` folder:

    .
    ├── dist
    │   ├── index.html 
    │   ├── 5df766af1ced8ff1fe0a.css
    │   └── 5df766af1ced8ff1fe0a.js

