#!/bin/bash
[[ -z "$1" ]] && { echo 'No package name is given.'; exit 1; }
packagename="$1"
if [ -z "$2" ]; then
  now="$(date +'%Y-%m-%d')"
else
  now=$2
fi

# --- Create folder and repo ---

mkdir "$now-$packagename"
cd "$now-$packagename"
git init
gh repo create -y --public git@github.com:bencsbalazs/"$now-$packagename".git
cat << EOF > package.json
{
  "name": "${now}-${packagename}",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "complexity": "cr src",
    "lint": "eslint ."
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/bencsbalazs/${now}-${packagename}.git"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "bugs": {
    "url": "https://github.com/bencsbalazs/${now}-${packagename}/issues"
  },
  "homepage": "https://github.com/bencsbalazs/${now}-${packagename}#readme",
  "dependencies": {
    "chai": "^4.3.4"
  },
  "devDependencies": {
    "complexity-report": "*",
    "eslint": "^7.29.0",
    "eslint-config-airbnb-base": "^14.2.1",
    "eslint-config-prettier": "^8.3.0",
    "eslint-plugin-import": "^2.23.4",
    "eslint-plugin-prettier": "^3.4.0",
    "jest": "^27.0.5",
    "prettier": "^2.3.1"
  }
}
EOF

# --- Create git actions ---

mkdir .github
mkdir .github/workflows

cat << EOF > .github/workflows/test.yml
name: Testing

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:

    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [12.x]

    steps:
    - uses: actions/checkout@v2
    - name: Use Node.js 12.x
      uses: actions/setup-node@v2
      with:
        node-version: 12.x
    - run: npm i
    - run: npm run test

EOF

cat << EOF > .github/workflows/lint.yml
name: Linting

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:

    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [12.x]

    steps:
    - uses: actions/checkout@v2
    - name: Use Node.js 12.x
      uses: actions/setup-node@v2
      with:
        node-version: 12.x
    - run: npm i
    - run: npm run lint

EOF

cat << EOF > .gitignore
coverage
node_modules
package-lock.json
EOF

cat << EOF > test
#!/bin/bash
npm test -- --watchAll --collect-coverage
EOF
chmod a+x test
git add test
git update-index --chmod=+x test

# ---------------------------------------------------
# --- Initializing tests and complexity reporting ---
# ---------------------------------------------------

npm i
touch complexity-report.md

cat << EOF > .complexrc
{
  "output": "complexity-report.md",
  "format": "markdown",
  "allfiles": false,
  "ignoreerrors": true,
  "filepattern": "(.(?<!\\\\.test))\\\\.js$",
  "dirpattern": ".+",
  "maxfiles": 256,
  "maxcyc": 4,
  "silent": false,
  "logicalor": false,
  "switchcase": false,
  "forin": false,
  "trycatch": false,
  "newmi": false
}
EOF

cat << EOF > generate-complexity-report
#!/bin/bash
npm run complexity
EOF

cat << EOF > .jshintrc
{
    "esversion": 6
}
EOF

chmod a+x generate-complexity-report
git add generate-complexity-report
git update-index --chmod=+x generate-complexity-report

cat << EOF > .eslintrc.json
{
  "env": {
    "es6":true,
    "browser": true,
    "commonjs": true,
    "node": true,
    "jest": true
  },
  "extends": ["prettier", "airbnb-base", "eslint:recommended"],
  "parserOptions": {
    "ecmaVersion": 6,
    "sourceType": "module"
  },
  "rules": {
    "prettier/prettier": "error"
  },
  "plugins": ["prettier"],
  "globals": {
    "Atomics": "readonly",
    "SharedArrayBuffer": "readonly"
  }
}
EOF

cat << EOF > .vscode
{
  "editor.formatOnSave": true,
}
EOF

cat << EOF > prettier.config.js
module.exports = {
  tabWidth: 2,
  semi: true,
  singleQuote: true,
  trailingComma: 'es5',
};
EOF

cat << EOF > .git/hooks/pre-commit
#!/bin/bash
echo "Generating complexity report..."
./generate-complexity-report
git add complexity-report.md
EOF
chmod a+x .git/hooks/pre-commit
git add .git/hooks/pre-commit
git update-index --chmod=+x .git/hooks/pre-commit

# -----------------------------
# --- Generate source files ---
# -----------------------------

mkdir src
cat > src/"$now-$packagename".js <<EOL
const ${packagename} = () => {};

module.exports = { ${packagename} };
EOL

mkdir __tests__
cat > __tests__/"$now-$packagename".test.js <<EOL
const { expect } = require('chai');
const { ${packagename} } = require('../src/${now}-${packagename}');

describe('User story 1', () => {
  it('', () => {
    expect(${packagename}()).equal(undefined);
  });
  it.skip('', () => {});
});

describe('User story 2', () => {
  it.skip('', () => {});
  it.skip('', () => {});
});
EOL

cat > README.md <<EOL
# Exercise: ${now}-${packagename}

|[![Testing](https://github.com/bencsbalazs/${now}-${packagename}/actions/workflows/test.yml/badge.svg)](https://github.com/bencsbalazs/${now}-${packagename}/actions/workflows/test.yml)|[![Linting](https://github.com/bencsbalazs/${now}-${packagename}/actions/workflows/lint.yml/badge.svg)](https://github.com/bencsbalazs/${now}-${packagename}/actions/workflows/lint.yml)||

> Installed with automatic script

- Source file
- Basic test file
- Jest for testing (watch and coverage) 
- EsLint + Prettier for code style check
- Complexity check

## User story 1

> As a user, I have to know if the input is valid

- User test 1/1: It should be false if
- User test 1/2: It should be false if

## User story 2

> As a user, I have to know if returning the correct value

- User test 2/1: It should be false if
- User test 2/2: It should be false if
EOL

cat > TechDebt.md <<EOL
# Technical debt
EOL

cat > NOTES.md <<EOL
# Notes for pair programming

> Pomodoro 1

- Note

> Pomodoro 2

- Note

> Pomodoro 3

- Note

> Pomodoro 4

- Note

EOL

#cat package.json | jq '.scripts.test = $v' --arg v 'jest --coverage' | sponge package.json
#cat package.json | jq '.scripts.complexity = $v' --arg v 'cr src' | sponge package.json
#cat package.json | jq '.scripts.test:watch = $v' --arg v 'jest --watch' | sponge package.json
#cat package.json | jq '.scripts.lint = $v' --arg v 'eslint .' | sponge package.json

git add .
git commit -m "initialized repo with node & jest"
git branch -M main
git push origin main

code .
