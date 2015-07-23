# dartnow_cli

### Basic structure:

* /~/dartnow_gists
  * playground dir
  * created_gists dir
  * checkout_gists dir
  * dartnow.json file
  
### commands:

* init ✓
  * create a dartnow.json with username/password ✓
  * command `reset_playground` ✓
* reset_playground ✓
  * reset the playground ✓
* create ✓
  * create a new gist from `playground` dir ✓
  * command `add_snippet` ✓
  * clone the updated gist to `created_gists` ✓
  * command `reset_playground` ✓
* push [dir] ✓
  * pull changes (just to be sure)  ✓
  * commit changes from git dir ✓
  * push changes from git dir ✓
  * command `add` ✓
  * pull changes back locally ✓
* add [id] ✓
  * command `update_gist` ✓
  * add id to firebase (/new_ids.json) ✓
  * (for me only) command `update_snippet_secret` ✓
* update_gist [id] ✓
  * update the readme from the gist ✓
  * update the pubspec (add gist link) ✓
  * update the gist description ✓
* checkout_gist [id]
  * clone a gist to `checkout_gist` dir

### secret code
* update_new_snippets ✓
  * fetch all new ids ✓
  * command `update` [id] ✓
* update_secret [id] ✓
  * calculate snippet model ✓
  * add info to firebase ✓
  * command update_user [snippet.username]
  * delete from new.json ✓
* update_user [username] (later) ✓
  * get the github user info (name, id, email, avatar url) ✓
  * get the number of contributed gist to dartnow ✓
  * the number of stars of those gists (later)
  * add the info to firebase ✓
* delete_new_gist ✓
* delete_gist ✓
