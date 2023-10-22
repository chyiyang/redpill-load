import json
import xml.etree.cElementTree as ET

# read json file
with open('../rss/7.1.1/rss.json') as f:
    data = json.load(f)

# create xml structure
root = ET.Element("rss")
root.set("version", "2.0")
channel = ET.SubElement(root, "channel")
ET.SubElement(channel, "title").text = data["channel"]["title"]
ET.SubElement(channel, "link").text = data["channel"]["link"]
ET.SubElement(channel, "pubDate").text = data["channel"]["pubDate"]
ET.SubElement(channel, "copyright").text = data["channel"]["copyright"]

# add item elements
for item in data["channel"]["item"]:
    xml_item = ET.SubElement(channel, "item")
    ET.SubElement(xml_item, "title").text = item["title"]
    ET.SubElement(xml_item, "MajorVer").text = str(item["MajorVer"])
    ET.SubElement(xml_item, "MinorVer").text = str(item["MinorVer"])
    ET.SubElement(xml_item, "NanoVer").text = str(item["NanoVer"])    
    ET.SubElement(xml_item, "BuildPhase").text = item["BuildPhase"]
    ET.SubElement(xml_item, "BuildNum").text = str(item["BuildNum"])
    ET.SubElement(xml_item, "BuildDate").text = item["BuildDate"]
    ET.SubElement(xml_item, "ReqMajorVer").text = str(item["ReqMajorVer"])
    ET.SubElement(xml_item, "ReqMinorVer").text = str(item["ReqMinorVer"])
    ET.SubElement(xml_item, "ReqBuildPhase").text = str(item["ReqBuildPhase"])
    ET.SubElement(xml_item, "ReqBuildNum").text = str(item["ReqBuildNum"])
    ET.SubElement(xml_item, "ReqBuildDate").text = item["ReqBuildDate"]
    ET.SubElement(xml_item, "isSecurityVersion").text = str(item["isSecurityVersion"])
    for model in item["model"]:
        xml_model = ET.SubElement(xml_item, "model")
        ET.SubElement(xml_model, "mUnique").text = model["mUnique"]
        ET.SubElement(xml_model, "mLink").text = model["mLink"]
        ET.SubElement(xml_model, "mCheckSum").text = model["mCheckSum"]

# write to xml file
tree = ET.ElementTree(root)
tree.write("../rss_not_beauty.xml")


# make beauty xml file
import xml.dom.minidom

input_file = "../rss_not_beauty.xml"
output_file = "../rss/7.1.1/rss.xml"

dom = xml.dom.minidom.parse(input_file)

with open(output_file, 'w') as f:
    f.write(dom.toprettyxml())
    
