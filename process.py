#!/usr/bin/python
# coding=utf-8

import xml.etree.ElementTree
et = xml.etree.ElementTree
import subprocess
import re

control_file = "fcom/DATA/XML_N_FCOM_EZY_TF_N_EU_CA_20110407.xml"
output_dir = "html/"
data_dir= "fcom/DATA/"
fleet_script_file = "scripts/fleet.js"
xsl_dir = "xsl/"

class FCOMMeta:

    class Section:

        def __init__(self, title):
            self.title = title
            self.children = []
            self.du_list = []


        def add_child(self, sid):
            self.children.append(sid)


        def add_du(self, du_filename_tuple):
            self.du_list.append(du_filename_tuple)


    class Aircraft:

        def __init__(self, aat):
            self.aircraft = {}
            self.fleets = {}
            self.pseudofleets = {}
            for a in aat.findall("aircraft-item"):
                if a.attrib["acn"]:
                    self.aircraft[a.attrib["msn"]] = a.attrib["acn"]
                    if not self.pseudofleets.has_key(a.attrib["acn"][:-1] + "*"):
                        self.pseudofleets[a.attrib["acn"][:-1] + "*"] = set()
                    self.pseudofleets[a.attrib["acn"][:-1] + "*"].add(a.attrib["msn"])
                else:
                    self.aircraft[a.attrib["msn"]] = a.attrib["msn"]
                m = a.attrib["aircraft-model"]
                if not self.fleets.has_key(m):
                    self.fleets[m] = set()
                self.fleets[m].add(a.attrib["msn"])


        def applies_string(self, msnlist):
            msnset = set(msnlist)
            fleets = []
            for f in self.fleets.keys():
               if self.fleets[f] <= msnset:
                    fleets.append(f + " fleet")
                    msnset = msnset.difference(self.fleets[f])
            pseudofleets = []
            for p in self.pseudofleets.keys():
                if self.pseudofleets[p] <= msnset:
                    pseudofleets.append(p)
                    msnset = msnset.difference(self.pseudofleets[p])
            remaining = pseudofleets + [self.aircraft[X] for X in list(msnset)]
            remaining.sort()
            fleets.sort()
            return ", ".join(fleets + remaining)


        def msn_to_reg(self, msn):
            return self.aircraft[msn]


        def all(self):
            return self.aircraft


        def dump(self):
            for k in self.fleets.keys():
                print "\n", k, "fleet: "
                for a in self.fleets[k]:
                    if self.aircraft[a]:
                        print self.aircraft[a]
                    else:
                        print a


    class DUMetaQuery:

        def __init__(self, fnd):
            self.du_filename = ""
            self.msns = []
            self.filename_dict = fnd
            self.tdu = False


        def get_ac_list(self, filename):
            if filename != self.du_filename:
                self.scan_dumeta(filename)
            return self.msns

        def is_tdu(self, filename):
            if filename != self.du_filename:
                self.scan_dumeta(filename)
            return self.tdu


        def scan_dumeta(self, filename):
            e = et.ElementTree(None, data_dir + self.filename_dict[filename])
            self.tdu = False
            if e.getroot().attrib["tdu"] == "true":
                self.tdu = True
            m = e.find("effect").find("aircraft-ranges").find("effact").find("aircraft-range")
            if not et.iselement(m):
                self.msns = None
            else:
                self.msns = []
                for msn in m.text.split(" "):
                    #supposition: a pair of numbers together indicates all aircraft with MSNs between
                    #[:4] and [4:]
                    if len(msn) == 8:
                        for rangemsn in range(int(msn[:4]), int(msn[4:]) + 1):
                            self.msns.append(str(rangemsn))
                    else:
                        self.msns.append(msn)


    def __init__(self, control_file):
        self.sections = {}
        self.du_titles = {}
        self.du_meta_filenames = {}
        self.top_level_sids = []
        self.control = et.ElementTree(None, control_file)
        self.global_meta = et. ElementTree(None, control_file.replace(".xml", "_mdata.xml"))
        self.aircraft = self.Aircraft(self.global_meta.find("aat"))
        self.du_metaquery = self.DUMetaQuery(self.du_meta_filenames)
        for psl in self.control.getroot().findall("psl"):
            self.top_level_sids.append((psl.attrib["pslcode"],))
            self.__process_psl__(psl, ())


    def __process_psl__(self, elem, sec_id):
        i = sec_id + (elem.attrib["pslcode"],)
        self.sections[i] = []
        section = self.Section(elem.findtext("title"))
        self.sections[i] = section
        if self.sections.has_key(i[:-1]):
            self.sections[i[:-1]].add_child(i)
        for e in elem:
            if e.tag == "du-inv":
                self.__process_duinv__(e, section)
            elif e.tag == "group":
                self.__process_group__(e, section)
            elif e.tag == "psl":
                self.__process_psl__(e, i)


    def __process_duinv__(self, elem, section):
        retval = []
        data_files = []
        for s in elem.findall("du-sol"):
            data_file = s.find("sol-content-ref").attrib["href"]
            self.du_meta_filenames[data_file] = s.find("sol-mdata-ref").attrib["href"]
            data_files.append(data_file)
            self.du_titles[data_file] = elem.find("title").text
        section.add_du(tuple(data_files))


    def __process_group__(self, elem, section):
        #note: groups don't nest, and they only contain du-inv sections
        for s in elem.findall("du-inv"):
            self.__process_duinv__(s, section)


    def get_title(self, sid):
        return self.sections[sid].title


    def get_du_title(self, du_filename):
        return self.du_titles[du_filename]


    def get_dus(self, sid):
        return self.sections[sid].du_list


    def get_children(self, sid):
        return self.sections[sid].children


    def get_all_sids(self):
        retval = []
        for s in self.top_level_sids:
            retval.append(s)
            retval += self.get_descendants(s)
        return retval


    def get_descendants(self, sid):
        retval = []
        for c in self.get_children(sid):
            retval.append(c)
            retval += self.get_descendants(c)
        return retval


    def get_leaves(self, prune=3):
        retval = []
        for s in self.get_all_sids():
            if len(s) > prune: continue
            if len(s) == prune or not self.get_children(s):
                retval.append(s)
        return retval


    def get_fleet(self):
        return [(X, self.aircraft.aircraft[X]) for X in self.aircraft.aircraft]


    def affected(self, msn, du_filename):
        ac_list = self.du_metaquery.get_ac_list(du_filename)
        if not ac_list or msn in ac_list:
            return True
        return False


    def applies(self, du_filename):
        return self.du_metaquery.get_ac_list(du_filename)


    def notcovered(self, msnlist):
        return list(set(self.aircraft.all()) - set(msnlist))


    def applies_string(self, msnlist):
        return self.aircraft.applies_string(msnlist)



    def is_tdu(self, du_filename):
        return self.du_metaquery.is_tdu(du_filename)


    def dump(self):
        print "Sections:\n==========\n"
        for s in self.get_all_sids():
            section = self.sections[s]
            indent = " " * ((len(s) - 1) * 4)
            print indent, ".".join(s), ": ", section.title
            for du in self.get_dus(s):
                print indent, " ", du
        print "\n\nLeaves:\n=======\n"
        for l in self.get_leaves():
            print ".".join(l), ": ", self.get_title(l)
        print "\n\nMeta:\n=====\n"
        du_keys = self.du_meta_filenames.keys()
        du_keys.sort()
        for k in du_keys:
            print k, self.du_meta_filenames[k]
        print "\n\nAircraft:\n=========\n"
        self.aircraft.dump()
        print "\n\nAircraft list test\n"
        print self.affected("4556", "./DU/00000284.0001001.xml")
        print self.applies("./DU/00000284.0001001.xml")
        print self.applies("./DU/00000879.0002001.xml")
        print "\n\nDU titles:\n==========\n"
        du_titles_keys = self.du_titles.keys()
        du_titles_keys.sort()
        for k in du_titles_keys:
            print k, self.du_titles[k]


class FCOMFactory:

    def __init__(self, fcm, version):
        self.fcm = fcm #instance of FCOMMeta
        self.versionstring = version
        self.pagelist = self.fcm.get_leaves(3)
        self.pageset = set(self.pagelist)
        self.duref_lookup = {}
        self.__build_duref_lookup__()


    def build_fcom(self):
        self.write_fleet_js()
        self.make_index()
        for c, sid in enumerate(self.pagelist):
            prevsid, nextsid = None, None
            if c > 0:
                prevsid = self.pagelist[c - 1]
            if c < len(self.pagelist) - 1:
                nextsid = self.pagelist[c + 1]
            self.make_page(c, sid ,prevsid, nextsid)


    def __build_duref_lookup__(self):
        for sid in self.pagelist:
            sid_list = self.__build_sid_list__(sid)
            for s in sid_list:
                for du_list in self.fcm.get_dus(s):
                    duref = self.__du_to_duref__(du_list[0])
                    self.duref_lookup[duref] = (
                        self.__make_filename__(sid) + "#duid" + duref,
                        ".".join(s) + ": " + self.fcm.get_du_title(du_list[0]))


    def __du_to_duref__(self, du):
        #this is dependent on the intrinsic link between du filenames and durefs
        # - it may be brittle
        return du[5:].split(".")[0]


    def __build_sid_list__(self, sid):
        return [sid, ] + self.fcm.get_descendants(sid)


    def make_page(self, c, sid, prevsid, nextsid):
        filename = self.__make_filename__(sid)
        print "Creating:", filename
        tb = et.TreeBuilder()
        page_attributes = {"title": self.__make_page_title__(sid),
                           "version": self.versionstring}
        if prevsid:
            page_attributes["prev"] = self.__make_filename__(prevsid)
            page_attributes["prevtitle"] = ".".join(prevsid) + ": " + self.fcm.get_title(prevsid)
        if nextsid:
            page_attributes["next"] = self.__make_filename__(nextsid)
            page_attributes["nexttitle"] = ".".join(nextsid) + ": " + self.fcm.get_title(nextsid)
        tb.start("page", page_attributes)
        javascript_list = []
        for s in self.__build_sid_list__(sid):
            tb.start("section", {"sid": ".".join(s),
                                 "title": self.fcm.get_title(s)})
            for dul in self.fcm.get_dus(s):
                msnlist = []
                tb.start("du_container", {"id": self.__du_to_duref__(dul[0]),
                                          "title": self.fcm.get_du_title(dul[0])})
                for c, du in enumerate(dul):
                    du_attrib = {"href": data_dir + du,
                                 "title": self.fcm.get_du_title(du),
                                 "id": self.__du_to_duref__(du) + "-" + str(c)}
                    if self.fcm.is_tdu(du):
                        du_attrib["tdu"] = "tdu"
                    tb.start("du", du_attrib)
                    applies = self.fcm.applies(du)
                    if applies:
                        tb.start("applies", {})
                        applies_string = self.fcm.applies_string(applies)
                        msnlist.append((du_attrib["id"], applies, applies_string[:100]))
                        tb.data(applies_string)
                        tb.end("applies")
                    tb.end("du")
                if msnlist:
                    javascript_list.append(msnlist)
                    # if dul does not cover the entire fleet, we need to add a fake extra du
                    msns = []
                    for msnentry in msnlist:
                        msns.extend(msnentry[1])
                    nc = self.fcm.notcovered(msns)
                    if nc:
                        du_attrib = {"href": "",
                                     "title": self.fcm.get_du_title(dul[0]),
                                     "id": self.__du_to_duref__(dul[0]) + "-na"}
                        if self.fcm.is_tdu(du):
                            du_attrib["tdu"] = "tdu"
                        tb.start("du", du_attrib)
                        tb.start("applies", {})
                        applies_string = self.fcm.applies_string(nc)
                        msnlist.append((du_attrib["id"], nc, applies_string[:100]))
                        tb.data(applies_string)
                        tb.end("applies")
                        tb.end("du")
                tb.end("du_container")
            tb.end("section")
        tb.end("page")
        page_string= subprocess.Popen(["xsltproc", "--nonet", "--novalid", xsl_dir + "page.xsl", "-"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE
                                  ).communicate(et.tostring(tb.close(), "utf-8"))[0]
        #create javascript variables for controlling folding
        javascript_string = ""
        for folding_section in javascript_list:
            javascript_string += "["
            for dusection in folding_section:
                javascript_string += "['%s',%s,'%s']," % dusection
            javascript_string = javascript_string[:-1] + "],"
        javascript_string = javascript_string[:-1] + "];\n"
        javascript_string = "var folding = [" + javascript_string
        page_string = page_string.replace("<!--jsvariable-->", javascript_string)
        #replace xml links with xhtml links
        page_parts = re.split('<a class="duref" href="(\d+)">', page_string)
        duref_index = 1
        while duref_index < len(page_parts):
            duinfo = self.duref_lookup[page_parts[duref_index]]
            page_parts[duref_index] = ('<a class="duref" href="' +
                                       duinfo[0] +
                                       '">')
            if page_parts[duref_index + 1][:2] == "</":
                page_parts[duref_index] += duinfo[1]
            else:
                page_parts[duref_index] += duinfo[1].split()[0]
            duref_index += 2
        page_string = "".join(page_parts)
        #insert link bar
        page_string = page_string.replace("<!--linkbar-->", self.__build_linkbar__(sid))
        of = open(output_dir + filename, "w")
        of.write(page_string)


    def __make_page_title__(self, sid):
        titleparts = []
        for c in range(1, len(sid) + 1):
            titleparts.append(self.fcm.get_title(sid[:c]))
        return "[%s] %s" % (".".join(sid), " : ".join(titleparts))


    def __recursive_add_section__(self, ident, tb):
        if ident not in self.pageset:
            children = self.fcm.get_children(ident)
            self.__make_node_page__(ident, children)
            tb.start("section", {"title": self.fcm.get_title(ident),
                                 "ident": ".".join(ident),
                                 "href": self.__make_filename__(ident)})
            for s in children:
                self.__recursive_add_section__(s, tb)
            tb.end("section")
        else:
            tb.start("page", {"href": self.__make_filename__(ident)})
            tb.data(".".join(ident) + ": " + self.fcm.get_title(ident))
            tb.end("page")


    def __make_node_page__(self, ident, children):
        tb = et.TreeBuilder()
        tb.start("index", {"title": self.__make_page_title__(ident),
                          "ident": ".".join(ident),
                           "version": self.versionstring})
        for i in children:
            self.__recursive_add_section__(i, tb)
        tb.end("index")
        page_string= subprocess.Popen(["xsltproc", "--nonet", "--novalid", xsl_dir + "index.xsl", "-"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE
                                  ).communicate(et.tostring(tb.close(), "utf-8"))[0]
        page_string = page_string.replace("<!--linkbar-->", self.__build_linkbar__(ident))
        print "Creating node page", ident
        of = open(output_dir + self.__make_filename__(ident), "w")
        of.write(page_string)


    def make_index(self):
        tb = et.TreeBuilder()
        tb.start("index", {"title": "Contents",
                           "version": self.versionstring})
        for s in self.fcm.get_leaves(1):
            self.__recursive_add_section__(s, tb)
        tb.end("index")
        page_string= subprocess.Popen(["xsltproc", "--nonet", "--novalid", xsl_dir + "index.xsl", "-"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE
                                  ).communicate(et.tostring(tb.close(), "utf-8"))[0]
        of = open(output_dir + "index.html", "w")
        of.write(page_string)


    def __make_filename__(self, sid):
        retval = ""
        if sid:
            retval = ".".join(sid) + ".html"
        return retval


    def __build_linkbar__(self, sid):
        if not sid: return ""
        title_crop = 30
        tb = et.TreeBuilder()
        tb.start("div", {"class": "linkbar"})
        tb.start("p", {})
        tb.start("a", {"title": "Contents",
                       "href": "index.html"})
        tb.data("Contents")
        tb.end("a")
        for c in range(1, len(sid)):
            tb.data(" >> ")
            ident = sid[:c]
            title = ".".join(ident) + ": " + self.fcm.get_title(ident)
            tb.start("a", {"title": title,
                           "href": self.__make_filename__(ident)})
            tb.data(title[:title_crop])
            if len(title) > title_crop:
                tb.data("...")
            tb.end("a")
        tb.end("p")
        tb.end("div")
        return et.tostring(tb.close(), "utf-8")


    def write_fleet_js(self):
        open(fleet_script_file, "w").write(
            ("var fleet = { \n" +
             ",".join(["'%s':'%s'" % X for X in self.fcm.get_fleet()]) +
             "};\n"))



def main():
    fcm = FCOMMeta(control_file)
    ff = FCOMFactory(fcm, "April 2011")
    ff.build_fcom()


main()


