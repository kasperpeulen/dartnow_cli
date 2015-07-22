# dartnow_cli

### Basic structure:

* /~/dartnow_gists
  * playground dir
  * created_gists dir
  * checkout_gists dir
  * dartnow.json file
  
### commands:

* create_snippet
  * create a new gist from `playground` dir
  * command add_snippet
  * clone the updated gist to `created_gists`
* add_snippet [id]
  * add the gist to firebase
  * command `update_gist`
  * command `update_user`
* update_gist [id]
  * update the readme from the gist
  * update the pubspec (add gist link)
  * update the gist description
* update_user [username]
  * get the github user info
  * add the info to firebase
* checkout_gist [id]
  * clone a gist to `checkout_gist` dir
