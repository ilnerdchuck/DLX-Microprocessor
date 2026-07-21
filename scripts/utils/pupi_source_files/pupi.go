package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"slices"
	"strings"
)

// the basics is that every file that needs a component
// is put in a wating line until all it's requests are
// satisfied

type node struct {
	Name      string
	Got, Want map[string]struct{}
}

func main() {
	content, err := io.ReadAll(os.Stdin)
	if err != nil {
		panic(err)
	}
	files := strings.Split(string(content), "\n")
	nodes := make([]*node, 0, len(files))
	for _, name := range files {
		if strings.TrimSpace(name) == "" {
			continue
		}

		nn := &node{
			Name: name,
			Got:  map[string]struct{}{},
			Want: map[string]struct{}{},
		}

		f, err := os.Open(name)
		if err != err {
			panic(err)
		}

		s := bufio.NewScanner(f)

		// need to add priority to the packages
		// Types of files
		// Package only with constants => no entities found first to compile (No Got no Want => can bbe directly compiled)
		// Package with entities => need to sweep for entites and functions (Surely has Got and can have Want)
		// Entity => if no components needed has only Got but can request some packages for constants
		// Top Entity => can request other components "entities" has Want and less got

		// we can sweep if package or not, in general:
		// we see what entities declaration has and we put in the got
		// we see what components needs and put in the want
		// extra: we see what functions declares and put in the got
		// extra: we see what functions needs and put in the want
		// if no Want and no Got we output it (is a package with only constants)

		for s.Scan() {
			line := s.Text()
			line = strings.ToLower(line)

			// we need only the declatarions
			if strings.Contains(line, ";") {
				continue
			}

			ff := strings.Fields(line)

			if len(ff) == 0 {
				continue
			}

			// the component keyword means a request => thus a Want
			if idx := slices.Index(ff, "component"); idx != -1 {
				name := ff[idx+1]
				nn.Want[name] = struct{}{}
				continue
			}

			// the entity keyword means an entity declaration => thus a got
			if idx := slices.Index(ff, "entity"); idx != -1 {
				name := ff[idx+1]
				nn.Got[name] = struct{}{}
				continue
			}

			//If nothing found it will have Want and Got empty
		}
		nodes = append(nodes, nn)
	}

	//first we remove the ones without requests
	todel := []*node{}

	for _, nn := range nodes {
		// Simple package type
		if nn != nil {
			if len(nn.Want) == 0 && len(nn.Got) == 0 {
				// compile it
				fmt.Println(nn.Name)
				todel = append(todel, nn)
				// Delete the actual compiled node
				nodes = slices.DeleteFunc(nodes, func(n *node) bool { return slices.Contains(todel, n) })
			}
		}
	}

	// We iterate ass long as there is a file with a want
	// at each iteration we compile the nodes with only got
	// instances
	for {
		if len(nodes) == 0 {
			break
		}
		todel := []*node{}

		for _, nn := range nodes {
			// Exclude the top level entity
			if len(nn.Want) != 0 {
				continue
			}

			// We only give out things so we compile and erase from the
			// consumers
			if len(nn.Want) == 0 {
				fmt.Println(nn.Name)
			}

			todel = append(todel, nn)
			// delete from the other nodes what i just have compiled
			for _, consumer := range nodes {
				for what := range nn.Got {
					delete(consumer.Want, what)
				}
			}
		}
		// Delete the actual compiled node
		nodes = slices.DeleteFunc(nodes, func(n *node) bool { return slices.Contains(todel, n) })
	}

}
