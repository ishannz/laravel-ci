Includes
========================

 * PHP 7.4 (ubuntu 12.04 + ondrej ppa)
 * nginx
 * NVM with node 10, 12 (Default: 12)
 * Latest Chrome
 * yarn
 
 
Sample CircleCI config file
========================
```
version: 2
jobs:
  build:
    docker:
      - image: ishannz/laravel-ci
        environment:
          - DISPLAY=:99
          - CHROME_BIN=/usr/bin/google-chrome-stable
          - BASH_ENV: ~/.nvm/nvm.sh
      - image: circleci/mysql:5.7
        environment:
          - MYSQL_USER=root
          - MYSQL_ROOT_PASSWORD=ubuntu
          - MYSQL_DATABASE=circle_test
          - MYSQL_HOST=127.0.0.1

    working_directory: /var/www/site/

    steps:
      - checkout

      # Restart php, Nginx and Xvfb
      - run: service php7.4-fpm restart
      - run: service nginx restart
      - run:
          command: Xvfb :99 -screen 0 1280x1024x24
          background: true

      # Composer Cache + Installation
      - restore_cache:
          keys:
            - v1-composer-{{ checksum "composer.lock" }}
      - run: composer install -n --prefer-dist

      # Save all dependancies to cache
      - save_cache:
          key: v1-composer-{{ checksum "composer.lock" }}
          paths:
            - vendor

      # Change node version to 12
      - run: nvm use 12

      # NPM Cache + Installation
      - restore_cache:
          keys:
            - v2-npm-deps-{{ checksum "yarn.lock" }}
      - run: yarn install
      - save_cache:
          paths:
            - ./node_modules
            - /root/.cache/Cypress
          key: v1-npm-deps-{{ checksum "yarn.lock" }}

      - run: mv .circleci/.env.circleci .env
      - run: php artisan key:generate
      - run: chmod -R 0777 /var/www/site/storage/ && chmod -R 0775 /var/www/site/bootstrap/cache/

      # prepare the database
      - run: php artisan migrate

      # Ensure production build runs
      - run: yarn prod

      # PHP Tests
      - run: ./vendor/bin/phpunit

      # JS E2E tests
      - run: cp cypress.env.json.dist cypress.env.json
      - run: yarn e2e

      - store_artifacts:
          path: cypress/screenshots
          destination: cypress/screenshots

      - store_artifacts:
          path: cypress/videos
```
