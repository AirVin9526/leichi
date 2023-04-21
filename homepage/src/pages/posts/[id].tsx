import path from "path";
import { promises as fs } from "fs";
import { GetStaticProps } from "next";
import type { ReactElement } from "react";
import { Box } from "@mui/material";
import SideLayout from "@/layout/SideLayout";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeRaw from "rehype-raw";

import { getPostsIds, getPostsData } from "@/utils/posts";

export default function Posts({ article }: { article: string }) {
  return (
    <SideLayout>
      <Box id="markdown-body" className="markdown-body">
        <ReactMarkdown
          rehypePlugins={[rehypeRaw]}
          remarkPlugins={[[remarkGfm, { singleTilde: false }]]}
        >
          {article}
        </ReactMarkdown>
      </Box>
    </SideLayout>
  );
}

export async function getStaticPaths() {
  const paths = getPostsIds();
  return {
    paths,
    fallback: false,
  };
}

export const getStaticProps: GetStaticProps<{ article: string }> = async ({
  params,
}) => {
  const mdDir = path.join(process.cwd(), "./src/static/md/");
  const fileContents = await fs.readFile(
    path.join(mdDir, params?.id + ".md"),
    "utf8"
  );

  // const postsData = getPostsData();

  return {
    props: {
      article: fileContents,
      // postsData,
    },
  };
};
