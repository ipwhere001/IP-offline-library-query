import java.io.IOException;
import java.math.BigInteger;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

public class Ip {

    private Map<Long,Long> prefStart = new HashMap();
    private Map<Long,Long> prefEnd = new HashMap();
    private BigInteger[] endArr;
    private String[] addrArr;

    private static Ip instance = null;

    private Ip() {
        Path path = Paths.get("ipv6_city.dat");

        byte[] data = null;
        try {
            data = Files.readAllBytes(path);
        } catch (IOException e) {
            e.printStackTrace();
        }

        long numbers = unpackInt4byte(data[4], data[5], data[6], data[7]);

        for (int k = 0; k < numbers; k++) {
            int i = k * 12 + 4 +4;
            prefStart.put(unpackInt4byte(data[i+8], data[i+9], data[i+10], data[i+11]),unpackInt4byte(data[i], data[i + 1], data[i + 2], data[i + 3]));

            prefEnd.put(unpackInt4byte(data[i+8], data[i+9], data[i+10], data[i+11]),unpackInt4byte(data[i + 4], data[i + 5], data[i + 6], data[i + 7]));

        }

        int recordSize =  (int)unpackInt4byte(data[0], data[1], data[2], data[3]);
        endArr = new BigInteger[recordSize];
        addrArr = new String[recordSize];
        for (int i = 0; i < recordSize; i++) {
            int p = (int)numbers*12 + 4 + 4 + (i * 55);
//            long endipnum = unpackInt4byte(data[p+50], data[1 + p+50], data[2 + p+50], data[3 + p+50]);

            int offset = (int)unpackInt4byte(data[50 + p], data[50 + p+1], data[50 + p+2],data[50+p+3]);
            int length = data[50+p+4] & 0xff;
            BigInteger endipnum =  new BigInteger(new String(Arrays.copyOfRange(data,p,p+50)).replaceAll("\\*",""));
            endArr[i] = endipnum;

            addrArr[i] = new String(Arrays.copyOfRange(data,  offset, (offset + length)));
        }

    }

    public static synchronized Ip getInstance() {
        if (instance == null)
            instance = new Ip();
        return instance;
    }

    public String get(String ip) {

        String[] ips = ip.split("\\:");
        long pref = Long.parseLong(ips[0],16);
        BigInteger val = stringToBigInt(ip);
        if (prefStart.get(pref) == null || prefEnd.get(pref) == null) {
            return "保留|保留|||||||||||||||||";
        }
        long low = prefStart.get(pref), high = prefEnd.get(pref);
        long cur = low == high ? low : search(low, high, val);
        return addrArr[(int) cur];

    }

    private int search(long low, long high, BigInteger k) {
        int M = 0;
        while (low <= high) {
            int mid = (int)(low + high) / 2;

            BigInteger endipNum = endArr[mid];
            if (endipNum.compareTo(k)==0 || endipNum.compareTo(k)==1) {
                M = mid;
                if (mid == 0) {
                    break;
                }
                high = mid - 1;
            } else
                low = mid + 1;
        }
        return M;
    }

    private long unpackInt4byte(byte a, byte b, byte c, byte d) {
        return (a & 0xFFL) | ((b << 8) & 0xFF00L) | ((c << 16) & 0xFF0000L) | ((d << 24) & 0xFF000000L);

    }

    public static BigInteger stringToBigInt(String ipInString) {
        ipInString = ipInString.replace(" ", "");
        byte[] bytes;
        if (ipInString.contains(":"))
            bytes = ipv6ToBytes(ipInString);
        else
            bytes = ipv4ToBytes(ipInString);
        return new BigInteger(bytes);
    }

    private static byte[] ipv6ToBytes(String ipv6) {
        byte[] ret = new byte[17];
        ret[0] = 0;
        int ib = 16;
        boolean comFlag = false;// ipv4混合模式标记
        if (ipv6.startsWith(":"))// 去掉开头的冒号
            ipv6 = ipv6.substring(1);
        String groups[] = ipv6.split(":");
        for (int ig = groups.length - 1; ig > -1; ig--) {// 反向扫描
            if (groups[ig].contains(".")) {
                // 出现ipv4混合模式
                byte[] temp = ipv4ToBytes(groups[ig]);
                ret[ib--] = temp[4];
                ret[ib--] = temp[3];
                ret[ib--] = temp[2];
                ret[ib--] = temp[1];
                comFlag = true;
            } else if ("".equals(groups[ig])) {
                // 出现零长度压缩,计算缺少的组数
                int zlg = 9 - (groups.length + (comFlag ? 1 : 0));
                while (zlg-- > 0) {// 将这些组置0
                    ret[ib--] = 0;
                    ret[ib--] = 0;
                }
            } else {
                int temp = Integer.parseInt(groups[ig], 16);
                ret[ib--] = (byte) temp;
                ret[ib--] = (byte) (temp >> 8);
            }
        }
        return ret;
    }


    /**
     * ipv4地址转有符号byte[5]
     */
    private static byte[] ipv4ToBytes(String ipv4) {
        byte[] ret = new byte[5];
        ret[0] = 0;
        // 先找到IP地址字符串中.的位置
        int position1 = ipv4.indexOf(".");
        int position2 = ipv4.indexOf(".", position1 + 1);
        int position3 = ipv4.indexOf(".", position2 + 1);
        // 将每个.之间的字符串转换成整型
        ret[1] = (byte) Integer.parseInt(ipv4.substring(0, position1));
        ret[2] = (byte) Integer.parseInt(ipv4.substring(position1 + 1,
                position2));
        ret[3] = (byte) Integer.parseInt(ipv4.substring(position2 + 1,
                position3));
        ret[4] = (byte) Integer.parseInt(ipv4.substring(position3 + 1));
        return ret;
    }

    public String getFullIPv6(String ipv6) {
        //入参为::时，此时全为0
        if (ipv6.equals("::")) {
            return "0000:0000:0000:0000:0000:0000:0000:0000";
        }
        //入参已::结尾时，直接在后缀加0
        if (ipv6.endsWith("::")) {
            ipv6 += "0";
        }
        String[] arrs = ipv6.split(":");
        String symbol = "::";
        int arrleng = arrs.length;

        while (arrleng < 8) {
            symbol += ":";
            arrleng++;
        }
        ipv6 = ipv6.replace("::", symbol);

        String fullip = "";
        for (String ip : ipv6.split(":")) {
            while (ip.length() < 4) {
                ip = "0" + ip;
            }
            fullip += ip + ':';
        }
        return fullip.substring(0, fullip.length() - 1);
    }


    public static void main(String[] args) {

        Ip ip = Ip.getInstance();
        System.out.println(ip.get(ip.getFullIPv6("2001:250:2826::")));

    }

}
