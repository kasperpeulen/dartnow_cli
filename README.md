# dartnow_cli

### Basic structure:

* /~/dartnow_gists
  * playground dir
  * created_gists dir
  * checkout_gists dir
  * dartnow.json file
  
### commands:

* create
  * create a new gist from `playground` dir
  * command `add_snippet`
  * clone the updated gist to `created_gists`
* update [dir]
  * commit changes from git dir
  * push changes from git dir
  * command `add_snippet`
  * pull changes back locally
* add_snippet [id]
  * command `update_gist`
  * add the snippet to firebase
  * command `update_user`
* update_gist [id]
  * update the readme from the gist
  * update the pubspec (add gist link)
  * update the gist description
* update_user [username]
  * get the github user info (name, id, email, avatar url)
  * get the number of contributed gist to dartnow
  * the number of stars of those gists
  * add the info to firebase
* checkout_gist [id]
  * clone a gist to `checkout_gist` dir
