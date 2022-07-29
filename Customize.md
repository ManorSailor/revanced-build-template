# Customizing ReVanced Builds

Using this script, you can customize ReVanced in two ways:

* [Customize Builds](#build) - Select which app & variant to build
* [Customize Patches](#patches) - Select which patches to apply

---

## Customize Builds <a name="build"></a>

By default, this script will compile both variants (root & non-root) of YT & YTM. If you build a specific app & variant i.e, say YT Non-root. 
Edit the `.config` file located in the root of the repository.

### !IMPORTANT!
1. Add your desired app & variant in b/w the double quotes. DO NOT remove quotes.
2. Only enter all UPPERCASE or lowercase characters.
3. DO NOT add whitespace
4. Following is the list of accepted keywords:

```
yt OR YT
ytm OR YTM
root OR ROOT
non-root OR NON-ROOT
```

### Example Usage
Example content of `.config`

- If you want both Root & Non-root variant of YT
```bash
# Config file for customizing your build of ReVanced
readonly APP="yt"
readonly VARIANT=""
```
Note: It is the same for YTM, just add `ytm` or `YTM` instead of yt

- If you only want Non-root variant of both apps
```bash
# Config file for customizing your build of ReVanced
readonly APP=""
readonly VARIANT="non-root"
```
Note: Just add `root` or `ROOT` if you  only want root variants

- If you want a specific variant of a particular app
```bash
# Config file for customizing your build of ReVanced
readonly APP="yt"
readonly VARIANT="non-root"
```
Note: This will only compile non-root YT

## Customize Patches <a name="patches"></a>

By default the script will build ReVanced with ALL default* patches. Edit `.config` file to include/exclude patches from your build of ReVanced.

*Default: All patches except those which have to be ***included*** explicitly, i.e, using the `-i` flag while manually using the ReVanced CLI

### !IMPORTANT!
1. Each patch name MUST start from a NEWLINE AND there should be only ONE patch PER LINE
2. DO NOT add any other type of symbol or character, it will break the script! You have been warned!
3. Anything starting with a hash (`#`) will be ignored. Also, do not add hash or any other character after a patch's name
4. Both YT Music ReVanced & YT ReVanced are supported
5. DO NOT add `microg-patch` to the list of excluding patches.
6. `.config` contains some predefined lines starting with `#`. DO NOT remove them.

### Example
Example content of `.config`:

- Exclude pure black theme and keep `create` button:
```
amoled
disable-create-button
```

- Exclude patches for both Music & YouTube (order doesn't matter)
```
amoled
exclusive-background-playback
disable-create-button
premium-heading
tasteBuilder-remover
```

- Include patches for both Music & YouTube (order doesn't matter)
```
compact-header
hdr-auto-brightness
autorepeat-by-default
enable-debugging
force-vp9-codec
enable-wide-searchbar
```

## List of Available Patches

Refer to Official ReVanced [list of available patches](https://github.com/revanced/revanced-patches#list-of-available-patches).