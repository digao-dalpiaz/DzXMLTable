# DzXMLTable

## Delphi non-visual component to handle flexible dynamic table stored as XML file

![Delphi Supported Versions](https://img.shields.io/badge/Delphi%20Supported%20Versions-XE3..10.4-blue.svg)
![Platforms](https://img.shields.io/badge/Platforms-Win32%20and%20Win64-red.svg)
![Auto Install](https://img.shields.io/badge/-Auto%20Install%20App-orange.svg)
![VCL and FMX](https://img.shields.io/badge/-VCL%20and%20FMX-lightgrey.svg)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/C0C53LVFN)

- [What's New](#whats-new)
- [Component Description](#component-description)
- [Installing](#installing)
- [Example of use](#example-of-use)
- [Published Properties](#published-properties)
- [Public Properties](#public-properties)
- [Methods](#methods)
- [TDzRecord Object](#tdzrecord-object)

## What's New

- 03/27/2021

   - First version of component.

## Component Description

When you are working on your software project, you always need to store some data into a INI file or some text file, as a configuration file or other information.

So, the options you have is INI file, or plain text. And almost always you need a table with some fields.

In a plain text, you can use one record per line, and separate fields using tab character, or pipe character, or another one. But you have some problems with this method: you need to take care about the separator char, not using it at fields value; and you have a biggest problem: in a future version, if you need to add a column, you lose the compatibility at this file when there are already data stored.

If you are working with INI file, you can specify the field names, but even that, you have problems to store one record per section, and is difficult to reorder records, delete records and name the record.

But don't worry, here is the solution.

The DzXMLTable is a non-visual component where you can store records with fields and values, and you can name the field, so you don't need to worry at future versions. You can add new fields at any time, just reading and writing them.

*This is a new concept of my previous DzMiniTable component.*

## Installing

### Auto install

1. Download Component Installer from: https://github.com/digao-dalpiaz/CompInstall/releases/latest
2. Put **CompInstall.exe** into the component repository sources folder.
3. Close Delphi IDE and run **CompInstall.exe** app.

### Manual install

1. Open **DzXMLTable** package in Delphi.
2. Ensure **Win32** Platform and **Release** config are selected.
3. Then **Build** and **Install**.
4. If you want to use Win64 platform, select this platform and Build again.
5. Add sub-path Win32\Release to the Library paths at Tools\Options using 32-bit option, and if you have compiled to 64 bit platform, add sub-path Win64\Release using 64-bit option.

Supports Delphi XE3..Delphi 10.4

## Example of use

```delphi
type
  TContact = class
    ID: Integer;
    Name: string;
	Phone: string;
	Active: Boolean; //new field in some new program version
  end;

procedure LoadContactsExample(List: TObjectList<TContact>);
var
  XML: TDzXMLTable;  
  Rec: TDzRecord;
  Contact: TContact;
begin
  XML := TDzXMLTable.Create(nil);
  try
    XML.FileName := 'C:\Data.xml';
	XML.Load;
	
	for Rec in XML do
	begin
	  Contact := TContact.Create;
	  Contact.ID := Rec['ID'];
	  Contact.Name := Rec['Name'];
	  Contact.Phone := Rec['Phone'];	  
	  Contact.Active := Rec.ReadDef('Active', True); //saved xml in old version could not have this filed, so, read with default value.
	  List.Add(Contact);
	end;
	
  finally
    XML.Free;
  end;
end;
```

> The field name is always case-insensitive in all methods and properties parameter.

## Published Properties

`FileName: string` = Specifies the full XML file name to Open and Save the table

`RequiredFile: Boolean` = When this property is disabled (default), if the file does not exist at Open method, the table will be loaded empty without raising any exception.

`RequiredField: Boolean` = When this property is disabled (default), you can read a non-exitent field without raising and exception, returning `Unassigned` variant value.

## Public Properties

`Rec[Index: Integer]: TDzRecord` (default component property) = Returns record object by index.

`RecCount: Integer` = Returns record count.

## Methods

```delphi
procedure Load;
```
Load the table from file specified at FileName property

```delphi
procedure Save;
```
Save the table to file specified at FileName property

```delphi
procedure Clear;
```
Clear all data in the table

```delphi
function New(Index: Integer = -1): TDzRecord;
```
Create a new record in the table and returns record object. You can specify the new record position in the table, using `Index` parameter. If you leave `Index = -1`, the record wil be added at the end of the table.

```delphi
procedure Delete(Index: Integer);
```
Delete a record by index.

```delphi
function FindIdxByField(const Name: string; const Value: Variant): Integer;
```
Returns the first record index that matches same Name and Value. If no record is found, the function will return `nil`.

```delphi
function FindRecByField(const Name: string; const Value: Variant): TDzRecord;
```
Returns the first record object that matches same Name and Value. If no record is found, the function will return `nil`.

```delphi
function FindIdxBySameText(const Name: string; const Value: Variant): Integer;
```
Returns the first record index that matches same Name and Value, **where Value is compared as String using case-insensitive**. If no record is found, the function will return `nil`.

```delphi
function FindRecBySameText(const Name: string; const Value: Variant): TDzRecord;
```
Returns the first record object that matches same Name and Value, **where Value is compared as String using case-insensitive**. If no record is found, the function will return `nil`.

```delphi
procedure Move(CurIndex, NewIndex: Integer);
```
Moves a record from `CurIndex` to `NewIndex` position in the table.

## TDzRecord Object

### Properties

`Field[const Name: string]: Variant` = Returns or defines field value as variant by field name.
When getting field value, if the field does not exist, an exception will be raised, unless the `RequiredField` property is False (in this case, an `Unassigned` value will be returned.
When setting field value, if the field does not exist, it will be automatically created with specified name and value.

`FieldIdx[Index: Integer]: TDzField` = Returns field object by field index.

> Warning: One record can contain fields that are different from another record. So, you should never use a fixed index to a specific field (like a column) across the records.

`FieldCount: Integer` = Returns number of fields in this record.

### Methods

```delphi
function ReadDef(const Name: string; DefValue: Variant): Variant;
```
Returns field value by field name. If field does not exist in the record, return `DefValue`.

```delphi
function FindField(const Name: string): TDzField;
```
Returns field object by field name. If field does not exist, returns `nil`.

```delphi
function FieldExists(const Name: string): Boolean;
```
Returns true if field exists by specified field name.

```delphi
procedure ClearFields;
```
Clear all fields data in the record (It doesn't just remove the value from the fields, but the fields altogether).
