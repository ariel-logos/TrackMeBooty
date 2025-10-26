# TrackMeBooty

### What is it?
${\textsf{\color{lime}{TrackMeBooty}}}$ is an add-on for FFXI's third-party loader and hook Ashita (https://www.ashitaxi.com/).
The purpose of this add-on is to provide a tracker for a list of items defined by the player.
<br></br>

### How does it work?
This add-on uses ImGui to create a window that display the relevant information.
Chat commands are used to customize the tracking, save and load lists and change settings.
<br></br>

### Main features
${\textsf{\color{lime}{TrackMeBooty}}}$ presets itself as a small window and (if enabled) the picture of a friend pirate on top of it!
Through several commands the player is able to track items of interest (e.g. materials for a crafting recipe).
The main window will show the list of tracked items, the amount available to the player in all their inventories and the target quantity (if specified).
Notifications are displayed in the form of text (i.e. \[+1\]) and a speech bubble from the friendly pirate (if enabled).
Upon reaching the item quota (if specified) the relative item will be marked as complete (green text).
The text displaying the name of the items can also be clicked to open an the relative <a href="https://www.bg-wiki.com/" target="_blank">bg-wiki</a> page to read more about the item details and possible whereabouts in the game.

<br></br>

![1](https://github.com/user-attachments/assets/d3c14659-eec5-4a85-96ea-446118a8db27)|![2](https://github.com/user-attachments/assets/8bfa5ad6-8f4d-4313-b4e4-e68413362fd0)
:-------------------------|-------------------------
With best pirate fren on  | Without pirate fren :( 

<br></br>
      

### Why pirates?
When I developed this addon I had pirates stuck in my head thanks to some Spongebob episode.
(<a href="https://www.youtube.com/watch?v=gY_Evx9Kn4c" target="_blank">for refrence...</a>)
<br></br>

### Installation
Go over the <a href="https://github.com/ariel-logos/trackmebooty/releases" target="_blank">Releases</a> page, download the latest version and unpack it in the add-on folder in your Ashita installation folder.
<br></br>

### Compatibility Issues
No compatibility issues found so far.
<br></br>

### Commands
```/addon load trackmebooty``` Loads the add-on in Ashita.

```/addon unload trackmebooty``` Unloads the add-on from Ashita.

```/tmb track <item>``` Adds \<item\> to the tracked list, provided it's a valid item name.

```/tmb untrack``` Removes \<item\> from the list of tracked items.

```/tmb untrack all``` Clears the list of tracked items.

```/tmb save <list>``` Saves the current list of tracked items on a file with name <list>.

```/tmb load <list>``` Loads a previously saved <list> replacing the currently tracked items.

```/tmb list``` Prints the available lists saved by the player and available for loading.

```/tmb pirate``` Toggles the images of the pirate and speech bubble (he'll be sad if hide him :<).

```/tmb loadlast``` Toggles the option of automatically loading the last loaded list when the addon is started.

#### How do I delete saved item lists?
There is no command to delete the files containing the saved lists as I don't feel comfortable to code in system calls to delete files automaticallly.
To delete a saved list, navigate to your folder addon (```Ashita\addons\TrackMeBooty```) and locate the ```lists``` folder.
Delete any list you want to remove directly from that folder.
<br></br>
