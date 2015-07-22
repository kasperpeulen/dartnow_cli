# dartnow_cli

### Basic structure:

* /~/dartnow_gists
  * playground dir
  * created_gists
  * cloned_gists
  
### commands:

* create_snippet
  * create a new gist from playground dir
  * command add_snippet
  * clone the updated gist to `created_gists`
* add_snippet
  * update the readme from the gist
  * update the pubspec (add gist link)
  * update the gist description
  * add the gist to firebase
  * command update_user
* update_user
  * get the github user info
  * add the info to firebase
