# More Custom Fields Overview

The Custom Fields found in Movable Type Pro are a boon to creating a flexible and robust site. When the standard field types don't quite meet your needs however, get More Custom Fields!

* Checkbox Group: easily create a group of checkboxes
* Radio Buttons with Input: build a group of radio buttons, where the last option is a text input field
* Selected Entries: select other entries from a pop-up window, to easily create a related entries list or string multi-part articles together. Also, the number of entries selected is unlimited, and the order you specify is retained!
* Selected Pages: works just like Selected Entries, but for Pages!
* Selected Assets: as you may guess, this works just like Selected Entries and Selected Pages. Note that each asset type is registered as a separate custom field, so in addition to the generic "Selected Assets" custom field, "Selected Images," "Selected Audios," "Selected Videos," and "Selected Files" are also available to filter the types of asset you want the field to work with.
* Multi-Use Single-Line Text Group: don't let the crazy name scare you -- this field type allows you to create a reusable group of fields, perfect for including a list of your favorite bookmarks, for example.


# Prerequisites

* Movable Type Pro 4.2x or 4.3x


# Installation

To install this plugin follow the instructions found here:

http://tinyurl.com/easy-plugin-install

This plugin requires a newer version of the `YAML::Tiny` Perl module than is included with Movable Type. Included with this plugin (in the `extlib/` folder) is a newer version of YAML::Tiny. Copy from the plugin archive `extlib/YAML/Tiny.pm` to `$MT_HOME/extlib/YAML/Tiny.pm` to update Movable Type's copy of this plugin. **This is a required, non-optional step!**


# Configuration

More Custom Fields creates several additional field types that are available when defining custom fields:

* Checkbox Group
* Radio Buttons with Input
* Selected Entries
* Selected Pages
* Selected Assets (and "child" types: Selected Images, Selected Audios, Selected Videos, Selected Files, and any other type of registered asset)
* Multi-Use Single-Line Text Group

Use these field types as you would any other: from the Preferences menu select Custom Fields, and create a new custom field.

The **Checkbox Group** field type options should be specified in a comma-delimited list. Each item in the list will become a checkbox.

The **Radio Buttons with Input** field type options should be specified in a comma-delimited list. Each item in the list will become a radio button. The last item in the list will have a text input field appended to it, so you'll likely want to specify the last item as "Other" or similar.

The **Selected Entries** and **Selected Pages** field types provides the ability to select Entries or Pages -- as many as needed, in whatever order is needed. Specify a blog ID as this field's option to determine which blog's Entries (or Pages) are available for selection. Blog IDs must be separated with a comma to create a string (as in "1,12,19,37,112"), or the value "all" may be used to include all blogs. Leaving this field blank will make the current blog's Entries (or Pages) available.

The **Selected Assets** field type (and the related asset types) work similar to the Selected Entries and Selected Pages field types: select an unlimited number of assets in any order you wish. This field type has no options and works on the current blog only.

The **Multi-Use Single-Line Text Group** field type is a mouthful. A breakdown of this field: The Single-Line Text field is included with MT Pro and lets you create a one-line text field. This field type can have many single-line text fields grouped together. Lastly, this is a multi-use field and provides an "add another group" button to add a limitless recurrence of the text fields you've defined. A popular use for this is to display URLs (with "Link Name" and "Link URL" text fields), and being multi-use means that an author can provide many URLs. Specify a comma-separated list of text field labels. Example: "Link Name,Link URL".

Lastly, use your new fields! Don't forget to place them in your templates.

## Using More Custom Fields with your Theme

If you're building your site as a theme, custom fields can be specified and automatically created when the theme is applied (refer to Theme Manager for more information). A list of the field types along with their keys is below, which may help expedite your theme creation.

* Checkbox Group: `checkbox_group`
* Radio Buttons (with Input field): `radio_input`
* Selected Entries: `selected_entries`
* Selected Pages: `selected_pages`
* Multi-Use Single-Line Text Group: `multi_use_single_line_text_group`
* Selected Assets: `selected_assets`

Note that the Selected Assets field actually creates a different custom field for each type of asset field available (Selected Images, Selected Videos, etc). These fields can also be used, though because they are dynamically generated you'll need to determine the name of the field yourself. The following format is followed:

    selected_[asset type]s
    
So, valid field types defined by the Community Pack would include:

* Selected Audios: `selected_asset.audios`
* Selected Images: `selected_asset.images`
* Selected Videos: `selected_asset.videos`


# Template Tags

Each of the custom field types that More Custom Fields is handled slightly differently. You can use all of the familiar Movable Type template tags to work with any custom field data, but keep reading for some specific notes and tips!

## Checkbox Group field type

For an example use of the Checkbox Group field type, lets say you created a custom field named In the Toolbox, which generated the template tag `EntryDataIn_the_toolbox`.

Simply placing this tag in your template will cause it to produce a comma-separated list of whatever checkboxes were checked:

    <p>Tools: <mt:EntryDataIn_the_toolbox></p> 

...will output:

    <p>Tools: Hammer, Philips head screwdriver, Level</p> 

Use MT's `if` tag to check if a certain value has been selected. The following would only be printed if "Monkeywrench" were checked in the custom field.

    <mt:If tag="EntryDataIn_the_toolbox" like="Monkeywrench">
        <p>Look out! He's got a monkeywrench, and he's not afraid to use it!</p>
    </mt:If>

## Radio Buttons with Input field type

The Radio Buttons with Input field type is much simpler. It works just like the radio buttons field, in fact: any field you create will output the selected option: if Banana is selected, `<mt:EntryDataMy_favorite_fruit>` will output "Banana." Similar to the Checkbox Group field type, if you want to check if a certain option is selected use MT's `if` tag:

    <mt:If tag="EntryDataMy_favorite_fruit" eq="Banana">
        <p>Do you know how to defend yourself against a banana?</p>
    </mt:If> 

If the last option -- the "Other" option -- is selected, `<mt:EntryDataMy_favorite_fruit>` will output "Other: Grapefruit." That is, the name of the option followed by a colon and a space, and lastly the contents of the text field. If you want to output just the text entry and not the "Other: " precedent, use MT's `regex_replace` modifier:

    <mt:EntryDataMy_favorite_fruit regex_replace="Other: (.*)","$1"> 

## Selected Entries

The Selected Entries field lets you link to other entries. Publishing those entries is a more involved process than working with the other custom field types, but it is still a familiar process. But first, what happens if you just publish the the custom field?

    In this series: <mt:EntryDataMultipart_entry>

...will output:

    In this series: 119,120,123 

...which isn't very interesting. The numbers you see published here are entry IDs.

More Custom Fields includes a special block tag called `SelectedEntries` to help you output the kind of result you want! Using the SelectedEntries tag is the key to making this field useful: it makes your selected entries available with the full complement of tags available in the entry context. This tag takes one argument: `basename`. The basename of your custom field was created when you saved it; in this example it's `multi-part_entry`.

    <mt:SelectedEntries basename="multi-part_entry">
      <mt:If name="__first__">
        <ul>
      </mt:If>
            <li><a href="<mt:EntryPermalink>"><mt:EntryTitle></a></li>
      <mt:If name="__last__">
        </ul>
      </mt:If>
    </mt:SelectedEntries> 

Notice that within the SelectedEntries tag you can use the familiar tags found in the entry context, such as EntryTitle and EntryPermalink shown here, but any other tag will work, too.

## Selected Pages

Selected Pages works exactly like the Selected Entries field does -- except it uses Pages. More Custom Fields includes the block tag `SelectedPages` to help output your selection, which works just like the SelectedEntries block does. If you've created a Selected Pages custom field with the `basename` of `my_favorite_pages` you might use the SelectedPages block like this:

    <mt:SelectedPages basename="my_favorite_pages">
      <mt:If name="__first__">
        <ul>
      </mt:If>
            <li><a href="<mt:PagePermalink>"><mt:PageTitle></a></li>
      <mt:If name="__last__">
        </ul>
      </mt:If>
    </mt:SelectedPages>

## Selected Assets

Selected Assets also works like Selected Entries and Selected Pages -- except it uses assets. More Custom Fields includes the block tag `SelectedAssets` to help output your selection, which works just like the SelectedEntries block does. If you've created a Selected Assets custom field with the `basename` of `my_favorite_assets` you might use the SelectedPages block like this:

    <mt:SelectedAssets basename="my_favorite_assets">
      <mt:If name="__first__">
        <ul>
      </mt:If>
            <li><a href="<mt:AssetURL>"><mt:AssetLabel></a></li>
      <mt:If name="__last__">
        </ul>
      </mt:If>
    </mt:SelectedAssets>

## Multi-Use Single-Line Text Group

As previously noted, this field type is a mouthful. To recap, a breakdown of this field: The Single-Line Text field is included with MT Pro and lets you create a one-line text field. This field type can have many single-line text fields grouped together. Lastly, this is a multi-use field and provides an "add another group" button to add a limitless recurrence of the text fields you've defined.

A popular use for this is to display URLs (with "Link Name" and "Link URL" text fields), so let's use that as an example. I create a new field named "Favorite Links." Specify the text field names within Options as a comma-separated list: "Link Name,Link URL." Lastly, my template tag is set to `FavoriteLinks`.

Outputting the saved contents of this field requires some special handling, and a special block tag is created to help with this. The text "loop" is appended to the specified template tag name to create this special tag. In this example, the special block tag is called `FavoriteLinksLoop`. So now we've got:

    <h3>My Favorite Links</h3>
    <mt:FavoriteLinksLoop>
    </mt:FavoriteLinksLoop>

That doesn't output our content, however. Within the new Loop block tag, we need to output the variables containing the saved content. To do this you'll need to use the "dirified" name of your text labels. In our case, the text labels are "Link Name" and "Link URL," so the dirified names are `link_name` and `link_url`. Let's add these variables (and some HTML) to our template snippet:

    <h3>My Favorite Links</h3>
    <mt:FavoriteLinksLoop>
    <p><a href="<mt:Var name="link_url">"><mt:Var name="link_name"></a></p>
    </mt:FavoriteLinksLoop>

I've entered several links in the Favorite Links field I created, so it will output the following:

    <h3>My Favorite Links</h3>
    <p><a href="http://google.com">Google</a></p>
    <p><a href="http://danandsherree.com">danandsherree.com</a></p>
    <p><a href="http://eatdrinksleepmovabletype.com">Eat Drink Sleep Movable Type</a></p>

Also note that this field uses jQuery. If this field is used for author fields on user profile pages, you'll want to include jQuery in your Edit Profile template, or rewrite the Javascript for the field to work how you prefer.


# Known Issues

## Movable Type Pro 4.24 and Earlier

Movable Type Pro 4.24 and previous versions (and Motion betas 1 and 2) don't run the `api_post_save.author` callback when saving an author profile from `mt-cp.cgi`.

This means that if you've defined a Checkbox Group custom field type (or any other custom custom field type) for authors and you try to save those options through the `mt-cp.cgi` Edit Profile screen, the options will not be saved. Options are saved if you're editing through the `mt.cgi` Edit Profile screen. This bug doesn't affect Entry, Page, Folder, or Category objects.

This bug is fixed in Movable Type Pro 4.25. Bug # 92832
http://bugs.movabletype.org/default.asp?92832

