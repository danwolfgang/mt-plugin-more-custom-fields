# More Custom Fields Overview

**Note**: This version 2.0 update represents a significant overhaul to More
Custom Fields. Upgraders: be sure to read through the Prerequisite and
Installation sections of the documentation, below.

The Custom Fields found in Movable Type Pro are a boon to creating a flexible
and robust site. When the standard field types don't quite meet your needs
however, get More Custom Fields!

* Checkbox Group: easily create a group of checkboxes.

* Message: administrators can edit the contents of the Message field text
  area, but any other use can only read the contents. Useful for displaying
  instructions or other data you don't want the user to edit.

* Multi-Line Text (WYSIWYG): expands upon the standard Multi-Line Text field by adding the CKEditor WYSIWYG editor.

* Multi-Use Single-Line Text Group: don't let the crazy name scare you -- this
  field type allows you to create a reusable group of fields, perfect for
  including a list of your favorite bookmarks, for example.

* Multi-Use Time Stamped Multi-Line Text: another mouthful of a field name,
  but easy to use. This field type provides a reusable Multi-Line text field.
  When saved, each Multi-Line text field has a time stamp saved with it.

* Radio Buttons with Input: build a group of radio buttons, where the last
  option is a text input field.

* Reciprocal Entry Association: used to link two entries together. When
  editing Entry A and linking Entry B, an association from Entry B back to
  Entry A is automatically created. When deleting an association, the
  reciprocal is also removed. The best part: on the Edit Entry screen is a
  link to edit the reciprocal Entry, allowing authors to easily jump between
  Entries.

* Reciprocal Page Association: just like Reciprocal Entry Association, but for
  Pages.

* Selected Entries: select other entries from a pop-up dialog, to easily
  create a related entries list or string multi-part articles together. The
  number of entries selected is unlimited, entries can be sorted by drag and
  drop, and Edit/View links are available for the linked entries.

* Selected Pages: works just like Selected Entries, but for Pages!

* Selected Entries Or Pages: works just like Selected Entries, but allows you
  to select a combination of Entries and Pages.

* Selected Assets: as you may guess, this field also works like Selected
  Entries: select assets from a popup dialog. Note that each asset type is
  registered as a separate custom field, so in addition to the generic
  "Selected Assets" custom field, "Selected Images," "Selected Audios,"
  "Selected Videos," and "Selected Files" are also available to filter the
  types of asset you want the field to work with.

* Selected Comments: again like the Selected Entries field, this field allows
  you to choose from published comments. The number of comments that can be
  selected is not limited, comments can be sorted by drag and drop, and an Edit
  link is available for the linked comments. (No View link is present because
  how and where you may publish comments can vary considerably.)

# Prerequisites

## Movable Type Pro 4.2x or Greater

This plugin works with Movable Type Pro 4.2x or greater. Additionally required:

* [Config Assistant](https://github.com/openmelody/mt-plugin-configassistant)

## Movable Type Pro 5.12 or greater

This plugin works with Movable Type Pro 5.12 or greater and does *not* require
Config Assistant (though to be clear, it specifically does not use this plugin
because it's not yet MT5 compatible). Installation requires an additional
(likely familiar) step, noted below.

# Installation

To install this plugin follow the instructions found here:

http://tinyurl.com/easy-plugin-install

This plugin requires a newer version of the `YAML::Tiny` Perl module (1.4.4)
than is included with Movable Type. Included with this plugin (in the
`extlib/` folder) is a newer version of `YAML::Tiny`. Copy from the plugin
archive `extlib/YAML/Tiny.pm` to `$MT_HOME/extlib/YAML/Tiny.pm` to update
Movable Type's copy of this plugin. **This is a required, non-optional step!**

This plugin requires a newer version of the jQuery library (1.7.x or greater)
than is included with Movable Type. Included with this plugin (in the
`jQuery/` folder) is a newer version of JQuery. Copy from `jQuery/jquery.js`
to `$MT_HOME/mt-static/jquery/jquery.js` to update Movable Type's copy of
jQuery. ** This is a required, non-optional step!**

## Movable Type 5 Installation

Install as noted above. Be sure to update `YAML::Tiny` as instructed.

Movable Type 5.1x includes jQuery version 1.4.x and so needs to be updated.
Movable Type 5.2 includes jQuery version 1.7.2 and therefore does *not* need
to be updated.

Static content needs to be copied. (This is handled automatically with Movable
Type 4 and Config Assistant, but needs to be manually done with MT5.) Copy the
contents of `$MT_HOME/plugins/MoreCustomFields/static/` to
`$MT_HOME/mt-static/support/plugins/morecustomfields/`.

# Configuration

More Custom Fields creates several additional field types that are available
when defining custom fields:

* Checkbox Group
* Message
* Multi-Line Text (WYSIWYG)
* Multi-Use Single-Line Text Group
* Multi-Use Time Stamped Multi-Line Text
* Radio Buttons with Input
* Reciprocal Entry Association
* Reciprocal Page Association
* Selected Entries
* Selected Pages
* Selected Entries or Pages
* Selected Assets (and "child" types: Selected Images, Selected Audios,
  Selected Videos, Selected Files, and any other type of registered asset)
* Selected Comments

Use these field types as you would any other: from the Preferences menu select
Custom Fields, and create a new custom field.

The **Checkbox Group** field type options should be specified in a
comma-delimited list. Each item in the list will become a checkbox.

The **Message** field type should receive a default value. This value is the
"message" displayed for all other users. The field options allow you to
specify whether *no* user should be able to edit the field data, or if
administrators should be able to override the supplied default.

The **Multi-Line Text (WYSIWYG)** field type is a textarea with the CKEditor WYSIWYG editor to the make text entry and formatting easy.

The **Multi-Use Single-Line Text Group** field type is a mouthful. A breakdown
of this field: The Single-Line Text field is included with MT Pro and lets you
create a one-line text field. This field type can have many single-line text
fields grouped together. Lastly, this is a multi-use field and provides an
"add another group" button to add a limitless recurrence of the text fields
you've defined. A popular use for this is to display URLs (with "Link Name"
and "Link URL" text fields), and being multi-use means that an author can
provide many URLs. Specify a comma-separated list of text field labels.
Example: "Link Name,Link URL".

The **Multi-Use Time Stamped Multi-Line Text** field type is another mouthful.
Breaking down this field: The Multi-Line Text field is included with MT Pro
and lets you create a textarea field. This field type also lets you create a
textarea field, and it can be re-used over and over simply by clicking an "add
another..." link. Additionally, each instance of the textarea is saved with a
time stamp, marking when the data in that textarea was added. This field has
no options.

The **Radio Buttons with Input** field type options should be specified in a
comma-delimited list. Each item in the list will become a radio button. The
last item in the list will have a text input field appended to it, so you'll
likely want to specify the last item as "Other" or similar.

The **Reciprocal Entry Association** and **Reciprocal Page Association** field
types allow you to link to an object of the same type, and automatically
create a reciprocal link: when you link Entry A and Entry B, Entry B is
automatically linked to Entry A. Note that the Reciprocal Entry Association
field can only associate Entries, and that the Reciprocal Page Association
field can only associate Pages. This field is non-functional for categories,
folders, and users. Specify a blog ID as this field's option to determine
which blog's Entries (or Pages) are available for selection. Blog IDs must be
separated with a comma to create a string (as in "1,12,19,37,112"), or the
value "all" may be used to include all blogs. Leaving this field blank will
use the current blog.

The **Selected Entries**, **Selected Pages**, **Selected Entries or Pages**,
and **Selected Comments** field types provides the ability to select those
object types -- as many as needed, sortable in whatever order is needed.
Specify a blog ID as this field's option to determine which blog's objects are
available for selection. Blog IDs must be separated with a comma to create a
string (as in "1,12,19,37,112"), or the value "all" may be used to include all
blogs. Leaving this field blank will make the current blog's objects available.

The **Selected Assets** field type (and the related asset types) work similar
to the Selected Entries field type: select an unlimited number of assets and
sort in any order you wish. This field type has no options and works on the
current blog only.

Lastly, use your new fields! Don't forget to place them in your templates.


## Using More Custom Fields with your Theme

If you're building your site as a theme, custom fields can be specified and
automatically created when the theme is applied (refer to Theme Manager for
more information). A list of the field types along with their keys is below,
which may help expedite your theme creation.

* Checkbox Group: `checkbox_group`
* Message: `message`
* Multi-Line Text (WYSIWYG): `wysiwyg_textarea`
* Multi-Use Single-Line Text Group: `multi_use_single_line_text_group`
* Multi-Use Time Stamped Multi-Line Text:
  `multi_use_timestamped_multi_line_text`
* Radio Buttons (with Input field): `radio_input`
* Reciprocal Entry Association: `reciprocal_entry`
* Reciprocal Page Association: `reciprocal_page`
* Selected Assets: `selected_assets`
* Selected Comments: `selected_comments`
* Selected Entries: `selected_entries`
* Selected Pages: `selected_pages`
* Selected Entries or Pages: `selected_content`

Note that the Selected Assets field actually creates a different custom field
for each type of asset field available (Selected Images, Selected Videos,
etc). These fields can also be used, though because they are dynamically
generated you'll need to determine the name of the field yourself. The
following format is followed:

    selected_[asset type]s

So, valid field types defined by the Community Pack would include:

* Selected Audios: `selected_asset.audios`
* Selected Images: `selected_asset.images`
* Selected Videos: `selected_asset.videos`


# Template Tags

Each of the custom field types that More Custom Fields is handled slightly
differently. You can use all of the familiar Movable Type template tags to
work with any custom field data, but keep reading for some specific notes and
tips!

## Checkbox Group field type

For an example use of the Checkbox Group field type, lets say you created a
custom field named In the Toolbox, which generated the template tag
`EntryDataIn_the_toolbox`.

Simply placing this tag in your template will cause it to produce a
comma-separated list of whatever checkboxes were checked:

    <p>Tools: <mt:EntryDataIn_the_toolbox></p> 

...will output:

    <p>Tools: Hammer, Philips head screwdriver, Level</p> 

Use MT's `if` tag to check if a certain value has been selected. The following
would only be printed if "Monkeywrench" were checked in the custom field.

    <mt:If tag="EntryDataIn_the_toolbox" like="Monkeywrench">
        <p>Look out! He's got a monkeywrench, and he's not afraid to use it!</p>
    </mt:If>

## Message

The Message custom field can be output simply using the tag you define for the
field. There are no special capabilities.

## Multi-Line Text (WYSIWYG)

The Multi-Line Text (WYSIWYG) field can be output simply by using the tag you define for the field. There are no special capabilities.

## Multi-Use Single-Line Text Group

As previously noted, this field type is a mouthful. To recap, a breakdown of
this field: The Single-Line Text field is included with MT Pro and lets you
create a one-line text field. This field type can have many single-line text
fields grouped together. Lastly, this is a multi-use field and provides an
"add another group" button to add a limitless recurrence of the text fields
you've defined.

A popular use for this is to display URLs (with "Link Name" and "Link URL"
text fields), so let's use that as an example. I create a new field named
"Favorite Links." Specify the text field names within Options as a
comma-separated list: "Link Name,Link URL." Lastly, my template tag is set to
`FavoriteLinks`.

Outputting the saved contents of this field requires some special handling,
and a special block tag is created to help with this. The text "loop" is
appended to the specified template tag name to create this special tag. In
this example, the special block tag is called `FavoriteLinksLoop`. So now
we've got:

    <h3>My Favorite Links</h3>
    <mt:FavoriteLinksLoop>
    </mt:FavoriteLinksLoop>

That doesn't output our content, however. Within the new Loop block tag, we
need to output the variables containing the saved content. To do this you'll
need to use the "dirified" name of your text labels. In our case, the text
labels are "Link Name" and "Link URL," so the dirified names are `link_name`
and `link_url`. Let's add these variables (and some HTML) to our template
snippet:

    <h3>My Favorite Links</h3>
    <mt:FavoriteLinksLoop>
    <p><a href="<mt:Var name="link_url">"><mt:Var name="link_name"></a></p>
    </mt:FavoriteLinksLoop>

I've entered several links in the Favorite Links field I created, so it will
output the following:

    <h3>My Favorite Links</h3>
    <p><a href="http://google.com">Google</a></p>
    <p><a href="http://danandsherree.com">danandsherree.com</a></p>
    <p><a href="http://eatdrinksleepmovabletype.com">Eat Drink Sleep Movable Type</a></p>

Also note that this field uses jQuery. If this field is used for author fields
on user profile pages, you'll want to include jQuery in your Edit Profile
template, or rewrite the Javascript for the field to work how you prefer.

## Multi-Use Time Stamped Multi-Line Text

A long name, but the idea is simple: this field provides a multi-line text
field that is saved with a time stamp. Add additional instances of this field
by clicking the "add another..." link. The time stamp will be saved with each
instance of the multi-line textarea. This field has no configuration options.

This field can be used in a "breaking news"-type entry, where there may be
many updates to the story as it unfolds. Since the textarea is time stamped
after each use, the exact time of each story addition can be published, making
it easy for readers to see exactly how and when this breaking news is
unfolding.

Outputting the contents of this field requires some special handling, and a
special block tag is created to help with this. The text "loop" is appended to
the specified template tag name to create this special tag. In this example
the custom field-created template tag is `BreakingNewsUpdates`, so the special
block tag is `BreakingNewsUpdatesLoop`.

Within this new tag we can output the variables containing the content added
to this field. The variables `text` and `date` are used, as in the example
below:

    <mt:BreakingNewsUpdatesLoop>
    <div class="breaking-news-update">
        <p><mt:Var name="text"></p>
        <p>Updated at <mt:Var name="date"></p>
    </div>
    </mt:BreakingNewsUpdatesLoop>

I've entered some simple text in the field, and when published it output the
following:

    <div class="breaking-news-update">
        <p>This is my first update to this story.</p>
        <p>Updated at July 27, 2011 4:56 PM</p>
    </div>
    <div class="breaking-news-update">
        <p>Another story update.</p>
        <p>Updated at July 28, 2011 8:12 AM</p>
    </div>

This custom field can be sorted in ascending or descending order (according to
the timestamp, of course). Use the `sort_order` key to specify "ascend" or
"descend". Ascend is the default.

The `text` variable can be optionally formatted with the [`filters`
modifier](http://www.movabletype.org/documentation/appendices/modifiers/filters.html).
The `date` variable can be optionally formatted with the [date formats
modifiers](http://www.movabletype.org/documentation/appendices/date-formats.html),
though placement of the arguments is unique. In the example below notice the
placement of the `format` argument: inside the Loop block.

    <mt:BreakingNewsUpdatesLoop format="%Y-%m-%e" sort_order="descend">
    <div class="breaking-news-update">
        <mt:Var name="text" filters="markdown_with_smartypants">
        <p>Updated at <mt:Var name="date"></p>
    </div>
    </mt:BreakingNewsUpdatesLoop>

## Radio Buttons with Input field type

The Radio Buttons with Input field type is much simpler. It works just like
the radio buttons field, in fact: any field you create will output the
selected option: if Banana is selected, `<mt:EntryDataMy_favorite_fruit>` will
output "Banana." Similar to the Checkbox Group field type, if you want to
check if a certain option is selected use MT's `if` tag:

    <mt:If tag="EntryDataMy_favorite_fruit" eq="Banana">
        <p>Do you know how to defend yourself against a banana?</p>
    </mt:If> 

If the last option -- the "Other" option -- is selected,
`<mt:EntryDataMy_favorite_fruit>` will output "Other: Grapefruit." That is,
the name of the option followed by a colon and a space, and lastly the
contents of the text field. If you want to output just the text entry and not
the "Other: " precedent, use MT's `regex_replace` modifier:

    <mt:EntryDataMy_favorite_fruit regex_replace="Other: (.*)","$1"> 

## Reciprocal Entry Association

The Reciprocal Entry Association field type allows you to link entries
together. Output the linked entry with a special block tag, `ReciprocalEntry`.
This tag takes one argument: basename. The basename of your custom field was
created when you saved it; in this example it's `my_reciprocal_entry`.

    <mt:ReciprocalEntry basename="my_reciprocal_entry">
        <p>Read this in Spanish: <a href="<mt:EntryPermalink>"><mt:EntryTitle></a></p>
    </mt:ReciprocalEntry>

As the text in the above example implies, the reciprocal entry could be
formatted with "read this in English" text to allow the user to go to their
preferred language.

## Reciprocal Page Association

The Reciprocal Page Association field type works just like the Reciprocal
Entry Association field type does, except that it uses a different block tag,
`ReciprocalPage`.

    <mt:ReciprocalPage basename="my_reciprocal_page">
        <p>Read this in Spanish: <a href="<mt:PagePermalink>"><mt:PageTitle></a></p>
    </mt:ReciprocalPage>

## Selected Entries

The Selected Entries field lets you link to other entries. Publishing those
entries is a more involved process than working with the other custom field
types, but it is still a familiar process. But first, what happens if you just
publish the the custom field?

    In this series: <mt:EntryDataMultipart_entry>

...will output:

    In this series: 119,120,123 

...which isn't very interesting. The numbers you see published here are entry
IDs.

More Custom Fields includes a special block tag called `SelectedEntries` to
help you output the kind of result you want! Using the SelectedEntries tag is
the key to making this field useful: it makes your selected entries available
with the full complement of tags available in the entry context. This tag
takes one argument: `basename`. The basename of your custom field was created
when you saved it; in this example it's `multi-part_entry`.

    <mt:SelectedEntries basename="multi-part_entry">
      <mt:If name="__first__">
        <ul>
      </mt:If>
            <li><a href="<mt:EntryPermalink>"><mt:EntryTitle></a></li>
      <mt:If name="__last__">
        </ul>
      </mt:If>
    </mt:SelectedEntries> 

Notice that within the SelectedEntries tag you can use the familiar tags found
in the entry context, such as EntryTitle and EntryPermalink shown here, but
any other tag will work, too.

## Selected Pages

Selected Pages works exactly like the Selected Entries field does -- except it
uses Pages. More Custom Fields includes the block tag `SelectedPages` to help
output your selection, which works just like the SelectedEntries block does.
If you've created a Selected Pages custom field with the `basename` of
`my_favorite_pages` you might use the SelectedPages block like this:

    <mt:SelectedPages basename="my_favorite_pages">
      <mt:If name="__first__">
        <ul>
      </mt:If>
            <li><a href="<mt:PagePermalink>"><mt:PageTitle></a></li>
      <mt:If name="__last__">
        </ul>
      </mt:If>
    </mt:SelectedPages>

## Selected Entries or Pages

Selected Entries or Pages works exactly like the Selected Entries field does
-- except it allows you to select any combination of Entries and Pages for a
single instance of this field. More Custom Fields includes the block tag
`SelectedEntriesOrPages` to help output your selection, which works just like
the SelectedEntries block does. If you've created a Selected Entries or Pages
custom field with the `basename` of `featured_content` you might use the
SelectedPages block like this:

    <mt:SelectedEntriesOrPages basename="featured_content">
      <mt:If name="__first__">
        <ul>
      </mt:If>
        <li>
            <mt:if tag="entryclass" eq="page"><img src="pageicon.gif"/><mt:else><img src="entryicon.gif"/></mt:if>
            <a href="<mt:EntryPermalink>"><mt:EntryTitle></a>
        </li>
      <mt:If name="__last__">
        </ul>
      </mt:If>
    </mt:SelectedEntriesOrPages>

*Note: Because Entries and Pages use the same base object type, `entry`, many
of the Entry tags can be used for Pages.*

## Selected Assets

Selected Assets also works like Selected Entries and Selected Pages -- except
it uses assets. More Custom Fields includes the block tag `SelectedAssets` to
help output your selection, which works just like the SelectedEntries block
does. If you've created a Selected Assets custom field with the `basename` of
`my_favorite_assets` you might use the SelectedPages block like this:

    <mt:SelectedAssets basename="my_favorite_assets">
      <mt:If name="__first__">
        <ul>
      </mt:If>
            <li><a href="<mt:AssetURL>"><mt:AssetLabel></a></li>
      <mt:If name="__last__">
        </ul>
      </mt:If>
    </mt:SelectedAssets>

## Selected Comments

Selected Comments also works like the Selected Entries field type -- except is
uses comments. More Custom Fields includes the block tag `SelectedComments` to
help output your selected.

# Known Issues

## Movable Type Pro 4.24 and Earlier

Movable Type Pro 4.24 and previous versions (and Motion betas 1 and 2) don't
run the `api_post_save.author` callback when saving an author profile from
`mt-cp.cgi`.

This means that if you've defined a Checkbox Group custom field type (or any
other custom custom field type) for authors and you try to save those options
through the `mt-cp.cgi` Edit Profile screen, the options will not be saved.
Options are saved if you're editing through the `mt.cgi` Edit Profile screen.
This bug doesn't affect Entry, Page, Folder, or Category objects.

This bug is fixed in Movable Type Pro 4.25. Bug # 92832
http://bugs.movabletype.org/default.asp?92832

