# portal
Bash Login Helper

Script that can be used with arguments to execute immediately, or with a small terminal-gui, to connect to a remote host using either ssh, sftp, or http (open a window in a browser). Connection details depend on the hosts listed in the .csv file

Example of how the menu can look like with some data inside:

![PORTAL](https://user-images.githubusercontent.com/12296614/235867351-4d4d59ef-c20f-47bf-b263-160924065265.png)

Example of how to use it within the terminal ():
![PORTAL1](https://user-images.githubusercontent.com/12296614/235867433-fd1c61fa-519e-4f91-b8b3-cae9844f486b.png)

For use via the terminal, you can use `entry_name` or `short_key_id`, here's an example with `short_key_id`:
![PORTAL5](https://user-images.githubusercontent.com/12296614/235870171-f73fb92f-a83f-4f19-b31a-ed2f2f151d37.png)

.csv file example (there are examples in the `./data` directory):
![PORTAL4](https://user-images.githubusercontent.com/12296614/235868774-497919e6-a56d-454c-ad2e-8ddd4dc30d0b.png)

Example how to list all connections:
![PORTAL3](https://user-images.githubusercontent.com/12296614/235868832-49cd05e0-baa1-41e5-a9cc-3ed2d6e52368.png)

Example how to search through all connections:
![PORTAL2](https://user-images.githubusercontent.com/12296614/235868945-67cd5703-35bc-4de6-838d-1804e19e3a44.png)


Help screen:
```ini
Usage: ./portal [http|ssh|sftp|--gui]..
Script is used to have a set of predetermined connections set up via .csv files, 
and then use the gui or supplied arguments to connect to the specificed connections.

General script output arguments
   -g, --gui                       enables gui menu for choosing a portal connection
   http|ssh|sftp [ARG]             connects using one of the supplied protocols
                    ^              ARG refers to the entry_id that is needed for a connection

   -s, --search                    search (with grep) through the list of existing connections
   -si, --search-case-insensitive                 search (with grep) through the list of existing connections
   -l, --list                      print all portal connections in a table onto stdout
   -b, --bash-completion           source the bash completion file, which updates the bash
                                    completion for any additional new data in the .csv files
   -i, --init                      create initial .config and bash completion file (by default
                                    located in /home/$(whoami)/.portal directory)
   -f, --force                     used in conjunction with --init, it forces an overwrite of
                                    the .config and bash completion files, in other words
                                    reinitialize them

Command usage examples
./portal --gui
./portal --list
./portal --search kubernetes
./portal http cicd_cluster_1
```
